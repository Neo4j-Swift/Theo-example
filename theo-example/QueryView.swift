import SwiftUI
import Theo

struct QueryView: View {
    let config: ConnectionConfig
    @StateObject private var viewModel = QueryViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Output text view area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.logMessages) { message in
                            Text(message.text)
                                .font(.system(size: 14))
                                .foregroundColor(message.isError ? .red : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.logMessages.count) { _, _ in
                    if let first = viewModel.logMessages.first {
                        withAnimation {
                            proxy.scrollTo(first.id, anchor: .top)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))

            Divider()

            // Buttons at bottom
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Button("Create Node") {
                        viewModel.createNode()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.isConnected)

                    Button("Fetch Node") {
                        viewModel.fetchNode()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.isConnected)
                }

                HStack(spacing: 8) {
                    Button("Run Cypher") {
                        viewModel.runCypher()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.isConnected)

                    Button("Run Transaction") {
                        viewModel.runTransaction()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.isConnected)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Queries")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.connect(with: config)
        }
    }
}

struct LogMessage: Identifiable {
    let id = UUID()
    let text: String
    let isError: Bool

    init(_ text: String, isError: Bool = false) {
        self.text = text
        self.isError = isError
    }
}

@MainActor
class QueryViewModel: ObservableObject {
    @Published var logMessages: [LogMessage] = []
    @Published var isConnected = false

    private var client: BoltClient?
    private var lastNodeId: UInt64 = 1

    func log(_ message: String, isError: Bool = false) {
        // Insert at beginning to match UIKit behavior (newest first)
        logMessages.insert(LogMessage(message, isError: isError), at: 0)
        print(message)
    }

    func connect(with config: ConnectionConfig) {
        log("Connecting...")

        do {
            client = try BoltClient(
                hostname: config.host,
                port: config.port,
                username: config.username,
                password: config.password,
                encrypted: config.encrypted
            )
        } catch {
            log("Failed during connection configuration: \(error)", isError: true)
            return
        }

        guard let client = client else { return }

        client.connect { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                Task { @MainActor in
                    self.log("Error while connecting: \(error)", isError: true)
                }
            case .success:
                client.executeCypher("MATCH (n:ImpossibleNode) RETURN count(n) AS n") { [weak self] queryResult in
                    guard let self = self else { return }
                    Task { @MainActor in
                        switch queryResult {
                        case .failure(let error):
                            self.log("Error while verifying connection: \(error)", isError: true)
                        case .success:
                            self.log("Connected successfully!")
                            self.isConnected = true
                        }
                    }
                }
            }
        }
    }

    func createNode() {
        guard let client = client else {
            log("Client not initialized yet", isError: true)
            return
        }

        let node = Node(label: "TheoTest", properties: [
            "prop1": "propertyValue_1",
            "prop2": "propertyValue_2"
        ])
        node["prop3"] = "Could add a property this way too"
        node.add(label: "AnotherLabel")

        client.createAndReturnNode(node: node) { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .failure(let error):
                    self.log("Error while creating node: \(error)", isError: true)
                case .success(let responseNode):
                    self.log("Successfully created node: \(responseNode)")
                    if let id = responseNode.id {
                        self.lastNodeId = id
                    }
                }
            }
        }
    }

    func fetchNode() {
        guard let client = client else {
            log("Client not initialized yet", isError: true)
            return
        }

        client.nodeBy(id: lastNodeId) { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .failure(let error):
                    self.log("Error while reading fetched node with ID '\(self.lastNodeId)': \(error)", isError: true)
                case .success(let responseNode):
                    if let responseNode = responseNode {
                        self.log("Fetched node with ID \(self.lastNodeId): \(responseNode)")
                    } else {
                        self.log("Could not find node with ID \(self.lastNodeId)")
                    }
                }
            }
        }
    }

    func runCypher() {
        guard let client = client else {
            log("Client not initialized yet", isError: true)
            return
        }

        client.executeCypher("MATCH (n:TheoTest) RETURN count(n) AS num") { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .failure(let error):
                    self.log("Error while getting cypher results: \(error)", isError: true)
                case .success((_, let queryResult)):
                    if let intNum = queryResult.rows.first?["num"] as? UInt64 {
                        self.log("Asked via Cypher how many nodes there are with label TheoTest. Answer: \(intNum)")
                    } else {
                        self.log("Got unexpected answer back")
                    }
                }
            }
        }
    }

    func runTransaction() {
        guard let client = client else {
            log("Client not initialized yet", isError: true)
            return
        }

        do {
            try client.executeAsTransaction { tx in
                let query = "CREATE (n:TheoTest { myProperty: $prop } )"
                client.executeCypher(query, params: ["prop": "A value"], completionBlock: nil)
                client.executeCypher(query, params: ["prop": "Another value"], completionBlock: nil)
            }
            log("Transaction completed successfully")
        } catch {
            log("Error while executing transaction: \(error)", isError: true)
        }
    }
}

#Preview {
    NavigationStack {
        QueryView(config: ConnectionConfig(
            host: "localhost",
            port: 7687,
            username: "neo4j",
            password: "neo4j",
            encrypted: false
        ))
    }
}
