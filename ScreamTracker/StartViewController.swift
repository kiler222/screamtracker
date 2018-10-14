//
//  StartViewController.swift
//  ScreamTracker
//
//  Created by kiler on 08.10.2018.
//  Copyright © 2018 kiler. All rights reserved.
//

import UIKit


class StartViewController: UIViewController, PassSavedFiles {

    
    func mySavedFiles(dictForSavedScreams : [String : String]) {
        // Handle the received data here
//        print(dictForSavedScreams)
        userSavedScreams = userSavedScreams.merging(dictForSavedScreams, uniquingKeysWith: { (first, _) in first })
       
//        print(userSavedScreams)
        
        let defaults = UserDefaults.standard
        defaults.set(userSavedScreams, forKey: "dictOfSavedScreams")
    }
    
    var mySavedScreams = [String : String]()
    
    var userSavedScreams = [String : String]()
    
    
   var licznik = 0
    
    @IBOutlet weak var startTrackingButton: UIButton!
    
    @IBAction func toToSavedScreams(_ sender: Any) {
        performSegue(withIdentifier: "goToSavedScreams", sender: self)
      //  print(userSavedScreams)
    }
    
    
    @IBOutlet weak var goToSavedButton: UIButton!
    
    @IBAction func goToScreamTracking(_ sender: Any) {
        
    performSegue(withIdentifier: "goToScreamTracking", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        print(userSavedScreams)
        if (UserDefaults.standard.object(forKey: "dictOfSavedScreams")) != nil {
        
            print("rozne od nil")
            print(UserDefaults.standard.object(forKey: "dictOfSavedScreams"))
//        let dictForSavedScreams = [String : String]()
//        UserDefaults.standard.set(dictForSavedScreams, forKey: "dictOfSavedScreams")
        } else{
            print("równe nil")
            print(UserDefaults.standard.object(forKey: "dictOfSavedScreams"))
                    let dictForSavedScreams = [String : String]()
                    UserDefaults.standard.set(dictForSavedScreams, forKey: "dictOfSavedScreams")
            print(UserDefaults.standard.object(forKey: "dictOfSavedScreams"))
        }
        
        startTrackingButton.layer.cornerRadius = 5
        startTrackingButton.clipsToBounds = false
        
        // shadow
        startTrackingButton.layer.shadowColor = UIColor.black.cgColor
        startTrackingButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        startTrackingButton.layer.shadowOpacity = 0.7
        startTrackingButton.layer.shadowRadius = 4.0
//
        
        goToSavedButton.layer.cornerRadius = 5
        goToSavedButton.clipsToBounds = false
        goToSavedButton.layer.shadowColor = UIColor.black.cgColor
        goToSavedButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        goToSavedButton.layer.shadowOpacity = 0.7
        goToSavedButton.layer.shadowRadius = 4.0
        //
        
        
        let fileManager = FileManager.default
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
//        if let pathComponent = url.appendingPathComponent(audioFilenames[indexPath.row]) {
//            let filePath = pathComponent.path
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
//        print(fileURLs)
            
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [])
//             print(directoryContents)
            
            
            let testFiles = directoryContents.filter{ $0.pathExtension == "m4a" }
//          print(testFiles)
            
            let testFileNames = testFiles.map{ $0.deletingPathExtension().lastPathComponent }
            
            let fileURLsWithScreamName = testFileNames.filter{ $0.contains("screamFile") }
//            print(fileURLsWithScreamName)
            for i in 0..<fileURLsWithScreamName.count{
                if let pathComponent = url.appendingPathComponent("\(fileURLsWithScreamName[i]).m4a") {
                    let filePath = pathComponent.path
//                    print(filePath)
                    do {
                        try fileManager.removeItem(atPath: filePath)
                       
                    }
                    catch let error as NSError {
                        print("Ooops! Something went wrong: \(error)")
                    }
                }
                
                
            }
            
            
        } catch {
            print(error)
        }
        
        
        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "goToScreamTracking" {
            let vc : ViewController = segue.destination as! ViewController
            vc.delegate = self
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
