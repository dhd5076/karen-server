import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    let locationController = LocationController()
    let messageController = MessageController()
    
    
    app.post("location", use: locationController.create)
    app.post("message", use: messageController.create)
}
