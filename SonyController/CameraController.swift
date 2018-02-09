//
//  CameraController.swift
//  SonyController
//
//  Created by Alexander Griswold on 1/14/18.
//  Copyright © 2018 com.example. All rights reserved.
//


//I need to have a live view image and a display image.
//The display image will be on top of the live view image.
//That way we can start downloading the live view once the image is downloaded.

//Call connectCamera to be able to make any API calls
//Call start live view to startLiveView and download liveView.


import UIKit
import SwiftyJSON

class CameraController: NSObject, URLSessionDelegate, URLSessionDataDelegate  {
    //liveview
    // 1
    var defaultSession: URLSession!
    // 2
    var dataTask: URLSessionDataTask!
    var buildingImage = false
    var myImageData = Data.init()
    var imageDataSize = Data.init(count: 0)
    var previousLiveViewFrame = #imageLiteral(resourceName: "whiteImage")
    var imageSize = 0
    var dataSize = 0
    var downloadedImage: UIImage? {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.imageDidDownload(image: self.downloadedImage!)
                self.startLiveView()
            }
        }
    }
    
    var imageURLs = [String]()
    var downloadedImages = [UIImage]()
    
    weak var delegate: CameraControllerDelegate? = nil
    
    override init() {
        super.init()
        
        let sessionConfiguration = URLSessionConfiguration.default
        defaultSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)

    }
    
    
    /*
     * Http post for any camera action.
     */
    func httpPost(method: String, params: [Any], version: String, id: Int) {
        
        print("HTTP")
        
        let json: [String: Any] = ["method": method, "params": params, "version": version, "id": id]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        
        
        // create post request
        let url = URL(string: "http://192.168.122.1:8080/sony/camera")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                //print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            
           
            
            if let responseJSON = responseJSON as? [String: Any] {
                //print("Camera Response: ", responseJSON["result"])
                
                for value in responseJSON.values {
                    print(type(of: value))
                    print(value)
                    
                }
                /*
                if let stuff = responseJSON["result"] {
                    print(stuff)
                }*/
            }
        }
        task.resume()
    }
    
    func stopContShooting() {
        let json: [String: Any] = ["method":"actTakePicture", "params":[], "version": "1.0", "id": 1]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "http://192.168.122.1:8080/sony/camera")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            
            let json = JSON(responseJSON)
            let imageLink = json["result"][0][0]
            
            let imageURL = URL(string: imageLink.description)
            
            if let imageURL = imageURL {
                let session = URLSession(configuration: .default)
                
                let downloadPicTask = session.dataTask(with: imageURL) { (data, response, error) in
                    // The download has finished.
                    if let e = error {
                        print("Error downloading cat picture: \(e)")
                    } else {
                        // No errors found.
                        // It would be weird if we didn't have a response, so check for that too.
                        if let res = response as? HTTPURLResponse {
                            print("Downloaded picture with response code \(res.statusCode)")
                            if let imageData = data {
                                // Finally convert that Data into an image and do what you wish with it.
                                let image = UIImage(data: imageData)
                                
                                if let image = image {
                                    self.downloadedImage = image
                                }
                                
                            } else {
                                print("Couldn't get image: Image is nil")
                            }
                        } else {
                            print("Couldn't get response code for some reason")
                        }
                    }
                }
                downloadPicTask.resume()
            }
        }
        task.resume()
    }
    
    /*
     * Connects the camera.
     */
    func connectCamera() {
        
        print("connecting camera")
        
        let json: [String: Any] = ["method":"startRecMode", "params":[], "version": "1.0", "id": 1]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "http://192.168.122.1:8080/sony/camera")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
           
            guard let data = data, error == nil else {
                //print(error?.localizedDescription ?? "No data")
                return
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            
            let json = JSON(responseJSON)
            if json["error"] == JSON.null {
                self.delegate?.cameraDidConnect(didConnect: true)
                self.startLiveView()
                
                /*
                let when = DispatchTime.now() + 10
                DispatchQueue.main.asyncAfter(deadline: when, execute: {
                    self.startLiveView()
                })
 */
            } else {
                self.delegate?.cameraDidConnect(didConnect: false)
            }
        }
        task.resume()
    }
    
    /*
     * Connects the camera.
     */
    func diconnectCamera() {
        self.httpPost(method: "stopRecMode", params: [], version: "1.0", id: 1)
    }
    
    
    /*
     * Calls stop downloading live view, waits one second, takes
     * a picture, and then downloads the image.
     */
    
    func startTakingPicture() {
        self.dataTask.suspend()
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.takePicture()
        }
    }
    
    func takePicture() {
        
        let json: [String: Any] = ["method":"actTakePicture", "params":[], "version": "1.0", "id": 1]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "http://192.168.122.1:8080/sony/camera")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            
            let json = JSON(responseJSON)
            let imageLink = json["result"][0][0]
            
            let imageURL = URL(string: imageLink.description)
            
            if let imageURL = imageURL {
                let session = URLSession(configuration: .default)
                
                let downloadPicTask = session.dataTask(with: imageURL) { (data, response, error) in
                    // The download has finished.
                    if let e = error {
                        print("Error downloading cat picture: \(e)")
                    } else {
                        // No errors found.
                        // It would be weird if we didn't have a response, so check for that too.
                        if let res = response as? HTTPURLResponse {
                            print("Downloaded picture with response code \(res.statusCode)")
                            if let imageData = data {
                                // Finally convert that Data into an image and do what you wish with it.
                                let image = UIImage(data: imageData)
                                
                                if let image = image {
                                    self.downloadedImage = image
                                }
                                
                            } else {
                                print("Couldn't get image: Image is nil")
                            }
                        } else {
                            print("Couldn't get response code for some reason")
                        }
                    }
                }
                downloadPicTask.resume()
            }
        }
        task.resume()
        
    }
    
    func startCont() {
        let json: [String: Any] = ["method":"startContShooting", "params":[], "version": "1.0", "id": 1]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "http://192.168.122.1:8080/sony/camera")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            
            let json = JSON(responseJSON)
            let error = json["error"]
            
            if error == JSON.null {
                
                print("HEY")
                
                self.delegate?.shootingDidStart()
            }
            
            
        }
        task.resume()
    }
    
    func downloadImage(imageLink: String) {
        
        let imageURL = URL(string: imageLink)
        
        if let imageURL = imageURL {
            let session = URLSession(configuration: .default)
            
            let downloadPicTask = session.dataTask(with: imageURL) { (data, response, error) in
                // The download has finished.
                if let e = error {
                    print("Error downloading cat picture: \(e)")
                } else {
                    // No errors found.
                    // It would be weird if we didn't have a response, so check for that too.
                    if let res = response as? HTTPURLResponse {
                        print("Downloaded picture with response code \(res.statusCode)")
                        if let imageData = data {
                            // Finally convert that Data into an image and do what you wish with it.
                            let image = UIImage(data: imageData)
                            
                            if let image = image {
                                //self.downloadedImage = image
                                self.downloadedImages.append(image)
                                self.downloadedImage = image
                                if self.imageURLs.count > 0 {
                                    self.downloadNextImage()
                                }
                                
                            }
                            
                            
                        } else {
                            print("Couldn't get image: Image is nil")
                        }
                    } else {
                        print("Couldn't get response code for some reason")
                    }
                }
            }
            downloadPicTask.resume()
        }
    }
    
    func downloadSet(linkString: String) {
        
        let imageURL = URL(string: linkString)
        if let imageURL = imageURL {
            let session = URLSession(configuration: .default)
            
            let downloadPicTask = session.dataTask(with: imageURL) { (data, response, error) in
                // The download has finished.
                if let e = error {
                    print("Error downloading cat picture: \(e)")
                } else {
                    // No errors found.
                    // It would be weird if we didn't have a response, so check for that too.
                    if let res = response as? HTTPURLResponse {
                        print("Downloaded picture with response code \(res.statusCode)")
                        if let imageData = data {
                            // Finally convert that Data into an image and do what you wish with it.
                            let image = UIImage(data: imageData)
                            
                            if let image = image {
                                self.downloadedImage = image
                            }
                            
                        } else {
                            print("Couldn't get image: Image is nil")
                        }
                    } else {
                        print("Couldn't get response code for some reason")
                    }
                }
            }
            downloadPicTask.resume()
        }
    }
    
    func setContinuousShooting() {
        
        struct JSONStuff: Codable {
            var id: Int
            var method: String
            var params: [[String: String]]
            var version: String
        }
        
        let thing = JSONStuff(id: 1, method: "setContShootingMode", params: [["contShootingMode": "Continuous"]], version: "1.0")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let data = try! encoder.encode(thing)
      
        
        
        // create post request
        let url = URL(string: "http://192.168.122.1:8080/sony/camera")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = data
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                //print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            
            
            
            if let responseJSON = responseJSON as? [String: Any] {
                //print("Camera Response: ", responseJSON["result"])
                
                for value in responseJSON.values {
                    print(type(of: value))
                    print(value)
                    
                }
                /*
                 if let stuff = responseJSON["result"] {
                 print(stuff)
                 }*/
            }
        }
        task.resume()
    }
    
    func setContShootingSpeed() {
        struct JSONStuff: Codable {
            var id: Int
            var method: String
            var params: [[String: String]]
            var version: String
        }
        
        let thing = JSONStuff(id: 1, method: "setContShootingSpeed", params: [["contShootingSpeed": "Hi"]], version: "1.0")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let data = try! encoder.encode(thing)
        
        
        
        // create post request
        let url = URL(string: "http://192.168.122.1:8080/sony/camera")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = data
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                //print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            
            
        }
        task.resume()
    }
    
    
    func checkIfLiveViewIsAvailable() {
        struct JSONStuff: Codable {
            var method: String
            var params: [Bool]
            var id: Int
            var version: String
        }
        
        var response: String
        
        let thing = JSONStuff(method: "getEvent", params: [true], id: 1, version: "1.2")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let data = try! encoder.encode(thing)
        
        // create post request
        let url = URL(string: "http://192.168.122.1:8080/sony/camera")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = data
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                //print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            
            let json = JSON(responseJSON)
            
            print(json)
            /*
            // Bool
            if let id = json["result"] {
                print("Liveview: ", id)
            } else {
                // Print the error
                print(json["result"][1]["cameraStatus"].error!)
            }
            */
            /*
            print("LiveView: ", otherThing)
            if otherThing == "hey" {
                self.startLiveView()
            } else {
                let when = DispatchTime.now() + 1
                DispatchQueue.main.asyncAfter(deadline: when, execute: {
                    self.checkIfLiveViewIsAvailable()
                })
            }
            */
        }
        task.resume()
    }
    
    func getEvent() {
        struct JSONStuff: Codable {
            var method: String
            var params: [Bool]
            var id: Int
            var version: String
        }
        
        let thing = JSONStuff(method: "getEvent", params: [true], id: 1, version: "1.2")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let data = try! encoder.encode(thing)
        
        // create post request
        let url = URL(string: "http://192.168.122.1:8080/sony/camera")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = data
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                //print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            
            let json = JSON(responseJSON)
           
            let otherThing = json["result"][3]["liveviewStatus"]
            
            print(otherThing.stringValue)
            /*
            let arrayNames =  json["result"][40]["contShootingUrl"].arrayValue.map({$0["postviewUrl"].stringValue})
            
            for name in arrayNames {
                print("ImageURL: ", name)
                
                self.imageURLs.append(name)
                
            }
            
            self.downloadImages()
            
            */
        }
        task.resume()
    }
    
    func downloadImages() {
        
        let imageCount = imageURLs.count
        
        
        if imageCount > 9 {
            //download first 10
            //I think the camera can only handle 10 requests at a time
            for index in 0...9 {
                self.downloadImage(imageLink: imageURLs[index])
            }
            
            for _ in 0...9 {
                self.imageURLs.removeFirst()
            }
            
        } else {
            downloadNextImage()
        }
        
    }
    
    func downloadNextImage() {
        
        if let imageURL = imageURLs.first {
            downloadImage(imageLink: imageURL)
            imageURLs.removeFirst()
        } else {
            print("No more images!")
        }
        
    }
    
    
    /*
     * Sends the start live view command to the camera and begins downloading.
     */
    func startLiveView() {
        
        print("connecting camera")
        
        let json: [String: Any] = ["method":"startLiveview", "params":[], "version": "1.0", "id": 1]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "http://192.168.122.1:8080/sony/camera")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let data = data, error == nil else {
                //print(error?.localizedDescription ?? "No data")
                return
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            
            let json = JSON(responseJSON)
            if json["error"] == JSON.null {
                self.downloadLiveView()
            } else {
                print("start live view failed")
            }
        }
        task.resume()
        
        
        //self.httpPost(method: "startLiveview", params: [], version: "1.0", id: 1)
        //self.downloadLiveView()
    }
    
    /*
     * Stops donwloading live view and then sends the command to start. 
     */
    func stopLiveView() {
        self.dataTask.suspend()
        self.httpPost(method: "stopLiveview", params: [], version: "1.0", id: 1)
    }
    
    /*
     * For live view. This starts the download of live view. Start live view needs to
     * be called first.
     */
    func downloadLiveView() {
        let url = NSURL(string: "http://192.168.122.1:8080/liveview/liveviewstream")
        dataTask = defaultSession.dataTask(with: url! as URL)
        dataTask?.resume()
    }
    
    /*
     * For live view. This takes all of the data from the URL Session and creates a UIImage.
     * If the image thats unwrapped is not an image then it returns the previous frame.
     */
    func buildImage() {
        
        let liveViewFrame = UIImage(data: myImageData)?.withHorizontallyFlippedOrientation()
        
        myImageData.removeAll()
        imageDataSize.removeAll()
        imageSize = 0
        
        if let liveViewFrame = liveViewFrame {
            previousLiveViewFrame = liveViewFrame
            delegate?.liveViewDidDownload(image: liveViewFrame)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        
        //if I'm building an image I want to append the data chunks that show up
        if buildingImage == true {
            
            
            if dataSize < imageSize {
                
                
                myImageData.append(data)
                dataSize += data.count
                
                
                if dataSize >= imageSize {
                    //print("data inside the thing: ", data)
                    buildingImage = false
                    buildImage()
                }
                //print("Data Size", dataSize)
                //print("Image Size", imageSize)
            } else {
                
                //print("data inside the thing: ", data)
                buildingImage = false
                buildImage()
                
            }
        } else {
            data.withUnsafeBytes {  (pointer: UnsafePointer<UInt8>) in
                
                
                if data.count >= 136 {
                    if pointer[0] == 255 && pointer[1] == 1 {
                        buildingImage = true
                        /*
                         print("Data Length: ", data.count)
                         print("Number 1: ", pointer[8])
                         print("Number 2: ", pointer[9])
                         print("Number 3: ", pointer[10])
                         print("Number 4: ", pointer[11])
                         */
                        imageDataSize.append(contentsOf: [pointer[12]])
                        imageDataSize.append(contentsOf: [pointer[13]])
                        imageDataSize.append(contentsOf: [pointer[14]])
                        
                        //print("Pointer: ", pointer[15])
                        
                        let myString = imageDataSize.hexEncodedString()
                        
                        let imageSize64 = UInt64(myString, radix:16)!
                        
                        imageSize = Int(imageSize64)
                        //print("FIRST IMAGE SIZE", imageSize)
                        
                        myImageData.append(data)
                        //sometimes the data is
                        myImageData.removeFirst(136)
                        dataSize = myImageData.count
                        
                    }
                }
            }
        }
    }
}

protocol CameraControllerDelegate: class {
    func imageDidDownload(image: UIImage)
    func liveViewDidDownload(image: UIImage)
    func shootingDidStart()
    
    //didConnect is true if connection was successul
    //false is connection was unsuccessful
    func cameraDidConnect(didConnect: Bool)
    
}

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}


