import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    let locationController = LocationController()
    let chatController = ChatController()
    
    
    app.post("location", use: locationController.create)
    app.post("chat", use: chatController.send)
}
