import SwiftUI

struct ErrorStateView: View {
    let title: String
    let message: String
    let onRetry: (() -> Void)?

    init(
        title: String = "Failed to load data",
        message: String,
        onRetry: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "EF4444").opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "EF4444"))
            }

            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text(message)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let onRetry = onRetry {
                Button(action: {
                    onRetry()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Retry")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.skyCyan)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

struct ErrorStateView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorStateView(message: "The request timed out. Please try again.", onRetry: {})
            .preferredColorScheme(.dark)
    }
}
