"""Keep only three source-PDF glyphs unsupported by iOS's Japanese fonts.

Requires pypdf and fonttools. The PDF's private-use glyphs are remapped to their
Unicode characters; no other glyphs from the embedded font are distributed.
"""
import argparse
from io import BytesIO
from pathlib import Path
from pypdf import PdfReader
from fontTools.ttLib import TTFont
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('root',type=Path)
args=parser.parse_args()
glyphs={'.notdef':TTGlyphPen(None).glyph()};metrics={'.notdef':(256,0)};cmap={}
for filename, mapping in [
 ('一字訓読み_１級訓読み表（生物・橙）.pdf',{0xe030:0x2cd6a,0xe031:0x29d97}),
 ('一字訓読み_１級訓読み表（道具・橙）.pdf',{0xe032:0x2b4bc})
]:
    pdf=PdfReader(args.root/filename)
    descendant=pdf.pages[0]['/Resources']['/Font']['/F2']['/DescendantFonts'][0].get_object()
    font=TTFont(BytesIO(descendant['/FontDescriptor']['/FontFile2'].get_data()))
    assert font['head'].unitsPerEm==256
    for pua,unicode in mapping.items():
        source=font.getBestCmap()[pua];name=f'u{unicode:X}'
        glyph=font['glyf'][source]
        assert glyph.numberOfContours>0 and not glyph.isComposite()
        # Clear source hinting: these outlines are rendered at arbitrary study sizes.
        glyph.removeHinting()
        glyphs[name]=glyph;metrics[name]=font['hmtx'][source];cmap[unicode]=name
builder=FontBuilder(256,isTTF=True)
builder.setupGlyphOrder(list(glyphs));builder.setupCharacterMap(cmap)
builder.setupGlyf(glyphs);builder.setupHorizontalMetrics(metrics)
builder.setupHorizontalHeader(ascent=230,descent=-26)
builder.setupNameTable({'familyName':'Kanji PDF Glyphs','styleName':'Regular','uniqueFontIdentifier':'KanjiPDFGlyphs-Regular-1','fullName':'Kanji PDF Glyphs Regular','psName':'KanjiPDFGlyphs-Regular','version':'Version 1.0'})
builder.setupOS2(sTypoAscender=230,sTypoDescender=-26,usWinAscent=256,usWinDescent=26)
builder.setupPost();builder.setupMaxp()
builder.font.recalcTimestamp = False
builder.font['head'].created=builder.font['head'].modified=3864153600
out=Path('KanjiBuildUp/Resources/KanjiPDFGlyphs.ttf');builder.save(out)
print(f'{out}: {len(cmap)} glyphs, {out.stat().st_size} bytes')
