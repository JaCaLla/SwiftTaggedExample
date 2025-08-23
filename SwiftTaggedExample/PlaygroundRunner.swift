import Foundation
import Tagged

@MainActor
final class PlaygroundRunner: ObservableObject {
    @Published var output: String = ""

    func clear() { output = "" }

    private func log(_ items: Any...) {
        let line = items.map { String(describing: $0) }.joined(separator: " ")
        output.append(line + "\n")
    }

    func run() {
        clear()
        demoRaw()
        demoTagged()
        demoCodable()
        demoHashable()
    }
}

// MARK: - Demos (adaptación del Playground)

private extension PlaygroundRunner {
    // ---------------------------------------------------------
    // ❌ 1. Problem using raw types" (UUID, String, etc.)
    // ---------------------------------------------------------

    struct UserRaw { let id: UUID }
    struct ProductRaw { let id: UUID }

    func registerPurchaseRaw(userID: UUID, productID: UUID) {
        log("✅ Purchase registered (RAW): user=\(userID) product=\(productID)")
    }

    func demoRaw() {
        log("— RAW demo —")
        let rawUser = UserRaw(id: UUID())
        let rawProduct = ProductRaw(id: UUID())

        // ❌ Compiles, BUT CODE SEMANTICALLY IS WRONG (crossed arguments)
        registerPurchaseRaw(userID: rawProduct.id, productID: rawUser.id)
        log("")
    }

    // ---------------------------------------------------------
    // ✅ 2. Solution by useing swift-tagged
    // ---------------------------------------------------------

    struct UserTag {}
    struct ProductTag {}

    typealias UserID = Tagged<UserTag, UUID>
    typealias ProductID = Tagged<ProductTag, UUID>

    struct User {
        let id: UserID
    }
    struct Product {
        let id: ProductID
    }

    func registerPurchase(userID: UserID, productID: ProductID) {
        log("✅ Purchase registered (Tagged): user=\(userID) product=\(productID)")
    }

    func demoTagged() {
        log("— Tagged demo —")
        let user = User(id: UserID(UUID()))
        let product = Product(id: ProductID(UUID()))
        registerPurchase(userID: user.id, productID: product.id)

        // ❌ This no longer compiles (type mismatch): // registerPurchase(userID: product.id, productID: user.id
       // registerPurchase(userID: product.id, productID: user.id)
        log("")
    }

    // ---------------------------------------------------------
    // 🌍 3. Codable + JSON  (API simularion)
    // ---------------------------------------------------------

    struct PurchaseRequest: Codable {
        let userID: UserID
        let productID: ProductID
    }

    func demoCodable() {
        log("— Codable + JSON —")

        let user = User(id: UserID(UUID()))
        let product = Product(id: ProductID(UUID()))
        let request = PurchaseRequest(userID: user.id, productID: product.id)

        // Encode → JSON
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(request)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                log("📤 JSON sent to server:")
                log(jsonString)
            }
        } catch {
            log("Encoding error:", error.localizedDescription)
        }

        // Decode ← JSON
        let jsonInput = """
        {
            "userID": "\(UUID())",
            "productID": "\(UUID())"
        }
        """.data(using: .utf8)!

        do {
            let decoded = try JSONDecoder().decode(PurchaseRequest.self, from: jsonInput)
            log("📥 JSON received and decoded to Swift struct:")
            log("userID: \(decoded.userID)")
            log("productID: \(decoded.productID)")
        } catch {
            log("Decoding error:", error.localizedDescription)
        }

        log("")
    }
    
    func demoHashable() {
        // ---------------------------------------------------------
        // 🔢 4. Using swift-tagged with Hashable collections
        // ---------------------------------------------------------

        // Sets of tagged IDs
        let user = User(id: UserID(UUID()))
        var seenUsers = Set<UserID>()
        seenUsers.insert(user.id)                 // from earlier code
        seenUsers.insert(UserID(UUID()))          // a different user
        seenUsers.insert(user.id)                 // duplicate; Set ignores it

        log("👥 Seen users (unique count): \(seenUsers.count)")

        // Dictionaries with tagged IDs as keys
        let product = Product(id: ProductID(UUID()))
        var productStock: [ProductID: Int] = [:]
        productStock[product.id] = 10             // from earlier code
        let anotherProductID = ProductID(UUID())
        productStock[anotherProductID] = 5

        log("📦 Product stock:")
        for (pid, qty) in productStock {
            log(" - \(pid): \(qty)")
        }

        // Using tagged IDs inside Hashable models
        struct CartItem: Hashable {
            let productID: ProductID
            let quantity: Int
        }

        var cart = Set<CartItem>()
        cart.insert(CartItem(productID: product.id, quantity: 1))
        cart.insert(CartItem(productID: product.id, quantity: 1)) // duplicate CartItem; Set ignores it
        cart.insert(CartItem(productID: product.id, quantity: 2)) // different (quantity), so distinct
        cart.insert(CartItem(productID: anotherProductID, quantity: 1))

        log("🛒 Cart unique items: \(cart.count)")

    }
}
