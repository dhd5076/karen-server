import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    let locationController = LocationController()
    let chatController = ChatController()
    
    //TODO: Create Route Collections
    
    //Location Routes
    app.post("location", use: locationController.create)
    
    //Chat Routes
    app.post("chat", use: chatController.send)
    app.get("chat", ":conversationID", use: chatController.getConversation)
}
