import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "suitcase.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.accentColor)

                Text("Packmate")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your smart packing companion.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button(action: {
                    // Action for getting started
                    
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
            }
            .padding()
            .navigationTitle("Welcome")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
