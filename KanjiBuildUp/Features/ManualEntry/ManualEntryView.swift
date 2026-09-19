import SwiftUI

struct ManualEntryView: View {
    let store: LearningStore
    let onAdd: () -> Void

    var body: some View {
        StudyItemEditor(store: store, onSave: onAdd)
    }
}
