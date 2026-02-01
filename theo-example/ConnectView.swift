import SwiftUI

struct ConnectView: View {
    @State private var hostname = ""
    @State private var port = ""
    @State private var username = ""
    @State private var password = ""
    @State private var useTLS = false
    @State private var navigateToQuery = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Hostname")
                            .frame(width: 80, alignment: .leading)
                        TextField("192.168.0.10", text: $hostname)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    HStack {
                        Text("Port")
                            .frame(width: 80, alignment: .leading)
                        TextField("7687", text: $port)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }

                    HStack {
                        Text("Username")
                            .frame(width: 80, alignment: .leading)
                        TextField("neo4j", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    HStack {
                        Text("Password")
                            .frame(width: 80, alignment: .leading)
                        SecureField("neo4j", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)
                    }

                    HStack {
                        Text("Use TLS")
                            .frame(width: 80, alignment: .leading)
                        Toggle("", isOn: $useTLS)
                            .labelsHidden()
                        Spacer()
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button("Connect") {
                    navigateToQuery = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Connection settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToQuery) {
                QueryView(config: connectionConfig)
            }
        }
    }

    private var connectionConfig: ConnectionConfig {
        ConnectionConfig(
            host: hostname.isEmpty ? "192.168.0.10" : hostname,
            port: Int(port) ?? 7687,
            username: username.isEmpty ? "neo4j" : username,
            password: password.isEmpty ? "neo4j" : password,
            encrypted: useTLS
        )
    }
}

#Preview {
    ConnectView()
}
