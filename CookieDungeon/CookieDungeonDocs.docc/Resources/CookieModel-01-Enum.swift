import Foundation

enum CookieModel: String, CaseIterable {
    case creamSoda = "Cream_Soda_Cookie_Epic_Skin"
    case prosciutto = "Prosciutto_Cookie"
    case marshmallowBunny = "Marshmallow_Bunny_Cookie"
    
    var filename: String {
        return self.rawValue
    }
}
