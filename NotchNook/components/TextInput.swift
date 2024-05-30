import SwiftUI

struct TextInputLabel: View {
    var label: String
    var body: some View {
        Text(label)
            .font(Font(NSFont.systemFont(ofSize: 12, weight: .semibold)))
            .opacity(0.75)
    }
}

struct TextInput: View {
    var opaque: Bool = false
    var label: String?
    @Binding var text: String
    @State private var isHovered: Bool = false
    @State private var timerCancel: TimerCancellable?
    @Binding var hideFix: Bool
    @State var myHideFix: Bool = false
    @FocusState private var isFocused: Bool
    var error: String?
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 2) {
            if let label = label {
                TextInputLabel(label: label)
            }
            ZStack(alignment: .trailing) {
                        TextField("", text: $text)
                            .textFieldStyle(.plain)
                            .focused($isFocused)
                .clipped()
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                .background(
                    RR(10, .secondary.opacity(isHovered ? 0.2 : 0.1 + (opaque ? 0.2 : 0)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isFocused ? Color.primary.opacity(0.3) : Color.clear)
                        )
                )
                .animation(.easeOut, value: isFocused)
                .onHover { isHovered in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        self.isHovered = isHovered
                    }
                }
                .onTapGesture {
                    isFocused = true
                }
                
                if let error = error {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                        .padding(.trailing, 8)
                        .allowsHitTesting(false)
                }
            }
            .animation(.linear, value: error)
        }
        
        //				.fixedSize()
        //				.frame(maxWidth: .infinity)
    }
}
