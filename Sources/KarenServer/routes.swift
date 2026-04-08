import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    let locationController = LocationController()
    let chatController = ChatController()
    let peopleController = PeopleController()
    
    //TODO: Create Route Collections
    
    //Location Routes
    app.post("location", use: locationController.create)
    
    //Chat Routes
    app.get("chat", ":conversationID", use: chatController.getConversation)
    app.post("chat", use: chatController.send)
    
    
    //People Routes
    app.get("people", use: peopleController.getAll)
    app.get("people", "search", use: peopleController.searchByName)
    app.get("people", ":personID", use: peopleController.getByID)
    app.post("people", use: peopleController.create)

}
