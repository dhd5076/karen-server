import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    let locationController = LocationController()
    let chatController = ChatController()
    
    //TODO: Create Route Collections
    
    //Location Routes
    app.post("location", use: locationController.create)
    
    //Chat Routes
    app.get("chat", ":conversationID", use: chatController.getConversation)
    app.post("chat", use: chatController.send)
    
    
    try app.register(collection: PeopleRoutes())
    try app.register(collection: PantryRoutes())
    try app.register(collection: TaskRoutes())
    try app.register(collection: HomeRoutes())
    try app.register(collection: WeatherRoutes())
    try app.register(collection: VehicleRoutes())
    try app.register(collection: AtlasRoutes())

}
