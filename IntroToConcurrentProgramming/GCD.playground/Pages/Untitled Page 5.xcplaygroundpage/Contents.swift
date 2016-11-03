//: [Previous](@previous)

import UIKit

class ImageProcessingOperation: Operation {
    
    init(image: UIImage) {
        self.image = image
        super.init()
    }
    
    override func main() {
        // Process the image, which takes a while
    }
    
    var image: UIImage
}

//: [Next](@next)
