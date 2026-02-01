import UIKit
import Theo

class QueryViewController: UIViewController {

    var connectionConfig: ConnectionConfig?
    @IBOutlet weak var outputTextView: UITextView?

    @IBOutlet weak var createNodeButton: UIButton?
    @IBOutlet weak var fetchNodeButton: UIButton?
    @IBOutlet weak var runCypherButton: UIButton?
    @IBOutlet weak var runTransactionButton: UIButton?


    private var theo: BoltClient?
    private var lastNodeId: UInt64 = 1

    override func viewDidLoad() {
        super.viewDidLoad()

        disableButtons()

        guard let config = connectionConfig else {
            outputTextView?.text = "Missing connection configuration"
            return
        }

        // Initialize the client
        do {
            self.theo = try BoltClient(
                hostname: config.host,
                port: config.port,
                username: config.username,
                password: config.password,
                encrypted: config.encrypted)
        } catch {
            log("Failed during connection configuration: \(error)")
            return
        }

        guard let theo = self.theo else { return }

        log("Connecting...")

        // Use callback-based connect (doesn't block main thread)
        theo.connect { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.log("Error while connecting: \(error)")
            case .success:
                // Verify connection with a simple query
                theo.executeCypher("MATCH (n:ImpossibleNode) RETURN count(n) AS n") { [weak self] queryResult in
                    guard let self = self else { return }
                    switch queryResult {
                    case let .failure(error):
                        self.log("Error while verifying connection: \(error)")
                    case .success:
                        self.log("Connected successfully!")
                        DispatchQueue.main.async {
                            self.enableButtons()
                        }
                    }
                }
            }
        }
    }

    private func enableButtons() {
        createNodeButton?.isEnabled = true
        fetchNodeButton?.isEnabled = true
        runCypherButton?.isEnabled = true
        runTransactionButton?.isEnabled = true
    }

    private func disableButtons() {
        createNodeButton?.isEnabled = false
        fetchNodeButton?.isEnabled = false
        runCypherButton?.isEnabled = false
        runTransactionButton?.isEnabled = false
    }

    @IBAction func createNodeTapped(_ sender: UIButton) {

        guard let theo = self.theo else {
            log("Client not initialized yet")
            return
        }

        let node = Node(label: "TheoTest", properties:
            ["prop1": "propertyValue_1",
             "prop2": "propertyValue_2"])
        node["prop3"] = "Could add a property this way too"
        node.add(label: "AnotherLabel")

        theo.createAndReturnNode(node: node) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .failure(error):
                self.log("Error while creating node: \(error)")
            case let .success(responseNode):
                self.log("Successfully created node: \(responseNode)")
                if let id = responseNode.id {
                    self.lastNodeId = id
                }
            }
        }
    }

    @IBAction func fetchNodeTapped(_ sender: UIButton) {

        guard let theo = self.theo else {
            log("Client not initialized yet")
            return
        }

        theo.nodeBy(id: lastNodeId) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .failure(error):
                self.log("Error while reading fetched node with ID '\(self.lastNodeId)': \(error)")
            case let .success(responseNode):
                if let responseNode = responseNode {
                    self.log("Fetched node with ID \(self.lastNodeId): \(responseNode)")
                } else {
                    self.log("Could not find node with ID \(self.lastNodeId)")
                }
            }
        }
    }

    func log(_ string: String) {
        print(string)
        DispatchQueue.main.async { [weak self] in
            let text = self?.outputTextView?.text ?? ""
            if text == "" {
                self?.outputTextView?.text = string
            } else {
                self?.outputTextView?.text = "\(string)\n\n\(text)"
            }
        }
    }

    @IBAction func runCypherTapped(_ sender: UIButton) {

        guard let theo = self.theo else {
            log("Client not initialized yet")
            return
        }

        theo.executeCypher("MATCH (n:TheoTest) RETURN count(n) AS num") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .failure(error):
                self.log("Error while getting cypher results: \(error)")
            case let .success((_, queryResult)):
                if let intNum = queryResult.rows.first?["num"] as? UInt64 {
                    self.log("Asked via Cypher how many nodes there are with label TheoTest. Answer: \(intNum)")
                } else {
                    self.log("Got unexpected answer back")
                }
            }
        }
    }

    @IBAction func runTransactionTapped(_ sender: UIButton) {
        guard let theo = self.theo else {
            log("Client not initialized yet")
            return
        }

        do {
            try theo.executeAsTransaction { tx in
                let query = "CREATE (n:TheoTest { myProperty: $prop } )"
                theo.executeCypher(query, params: ["prop": "A value"], completionBlock: nil)
                theo.executeCypher(query, params: ["prop": "Another value"], completionBlock: nil)
            }
            log("Transaction completed successfully")
        } catch {
            log("Error while executing transaction: \(error)")
        }
    }

}
