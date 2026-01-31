import Foundation
import Theo

// Command-line example demonstrating Theo 6.0 usage
// This is a simple macOS/Linux example showing how to connect to Neo4j

print("Theo Example - Neo4j Swift Driver Demo")
print("=======================================\n")

// Configuration
let hostname = "localhost"
let port = 7687
let username = "neo4j"
let password = "neo4j"

do {
    // Create the BoltClient
    let client = try BoltClient(
        hostname: hostname,
        port: port,
        username: username,
        password: password,
        encrypted: true
    )

    print("Connecting to Neo4j at \(hostname):\(port)...")

    // Connect synchronously
    let connectResult = client.connectSync()

    switch connectResult {
    case .failure(let error):
        print("Failed to connect: \(error)")
        exit(1)
    case .success:
        print("Connected successfully!\n")
    }

    // Create a node
    print("Creating a node...")
    let node = Node(label: "TheoExample", properties: [
        "name": "Test Node",
        "createdAt": "\(Date())"
    ])

    let createResult = client.createAndReturnNodeSync(node: node)

    switch createResult {
    case .failure(let error):
        print("Failed to create node: \(error)")
    case .success(let createdNode):
        print("Created node with ID: \(createdNode.id ?? 0)")
        print("Labels: \(createdNode.labels)")
        print("Properties: \(createdNode.properties)\n")

        // Fetch the node back
        if let nodeId = createdNode.id {
            print("Fetching node with ID \(nodeId)...")
            let fetchResult = client.nodeByIdSync(id: nodeId)

            switch fetchResult {
            case .failure(let error):
                print("Failed to fetch node: \(error)")
            case .success(let fetchedNode):
                if let fetchedNode = fetchedNode {
                    print("Fetched node: \(fetchedNode.properties)\n")
                } else {
                    print("Node not found\n")
                }
            }
        }
    }

    // Run a Cypher query
    print("Running Cypher query...")
    let cypherResult = client.executeCypherSync("MATCH (n:TheoExample) RETURN count(n) AS count")

    switch cypherResult {
    case .failure(let error):
        print("Cypher query failed: \(error)")
    case .success(let queryResult):
        if let count = queryResult.rows.first?["count"] as? UInt64 {
            print("Found \(count) TheoExample nodes in the database\n")
        }
    }

    // Disconnect
    client.disconnect()
    print("Disconnected from Neo4j")

} catch {
    print("Error initializing client: \(error)")
    exit(1)
}
