//
//  SavedScreamsViewController.swift
//  nagrywanie2
//
//  Created by kiler on 08.09.2018.
//  Copyright © 2018 kiler. All rights reserved.
//

import AudioKit
//import AudioKitUI
import UIKit
import GoogleMobileAds
import Charts
import Firebase
import Crashlytics
import SwipeCellKit


class SavedScreamsViewController: UIViewController, GADBannerViewDelegate, GADInterstitialDelegate, AVAudioPlayerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBAction func backtoFirstViewController(_ sender: Any) {
    
        self.dismiss(animated: true, completion: nil)
        
    }

    @IBOutlet weak var noSavedScreams: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    let cellReuseIdentifier = "SavedScreamsTableViewCell"
    
    var isSwipeRightEnabled = true
    var defaultOptions = SwipeOptions()
    var buttonStyle: ButtonStyle = .backgroundColor
    var buttonDisplayMode: ButtonDisplayMode = .imageOnly
   
    var timeStamp = [String]()
    
    var x: Int = 0 //counter do uzupełniania wykresu próbek
  
    var isFirstRun = true
    
    var pierwszyRaz = 0
    
    var dictOfAudioFloat = [String:[Float]]()
    
   
    var isPlayingScream: Bool = false
  
    var delta: Float = 0.0
    
    var numbersOfScreams: Int = 0
    var audioFilenames: [String] = []
    var playCounts = 0 //ile razy został odtworzony dzwiek, potrzebne do wyświetlania reklam interstitial
    
     var startSample: Int!
    var endSample: Int!
    
    var audioDataArray: [Float] = []
    
    var bannerView: GADBannerView!
    let request = GADRequest()
    
    var interstitial: GADInterstitial!
    
    
    let chartPoints: Int = 150
    
//    var tracker: AKFrequencyTracker!
//    var silence: AKBooster!
//    var clipRecoder: AKClipRecorder!
//    var recorder: AKNodeRecorder!
//    var micMixer: AKMixer!
//    var player: AKPlayer!
//    var tape: AKAudioFile!
    
    var sound: AVAudioPlayer!
  


    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        
        
        // This view controller itself will provide the delegate methods and row data for the table view.
 
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = .clear
        tableView.rowHeight = 90;
  
        request.testDevices = ["kGADSimulatorID", "b0aff17d3218b314d602d3ab5f425852"]
        
        // In this case, we instantiate the banner with desired ad size.
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
//        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716" //testowy admob
        bannerView.adUnitID = "ca-app-pub-8857410705016797/7011915857" // moj admob
        
        
        bannerView.rootViewController = self
        bannerView.load(request)
        bannerView.delegate = self
        
        
        interstitial = createAndLoadInterstitial()
        interstitial.delegate = self
        interstitial.load(request)

       
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            // process files
            
            if fileURLs.count != 0 {
       
                let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [])
               // print(directoryContents)
                
                let testFiles = directoryContents.filter{ $0.pathExtension == "m4a" }
                //print("testowe urls:",testFiles)
                let testFileNames = testFiles.map{ $0.deletingPathExtension().lastPathComponent }
                let tempDictOfSavedScreams =  UserDefaults.standard.object(forKey: "dictOfSavedScreams") as! [String:String]?
//                print("temp sved: \(tempDictOfSavedScreams)")
                for i in 0 ..< testFileNames.count {
                    print(testFileNames[i])
                    
                    if (tempDictOfSavedScreams?["\(testFileNames[i]).m4a"]) != nil {
                    audioFilenames.append("\(testFileNames[i]).m4a")
                    
                    dictOfAudioFloat["\(testFileNames[i]).m4a"] = prepareAudioDataFloat(audioFileName: "\(testFileNames[i]).m4a")
                    }
                }
            }else{
               noSavedScreams.isHidden = false
            
            }
            
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
       
        
    }
    
   
    
    
    //MARK: tableviewcell
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        print("ile wierszy: \(dictOfAudioFloat.keys.count)")
        return dictOfAudioFloat.keys.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        
        var dictOfSavedScreams = [String:String]()
        dictOfSavedScreams = (UserDefaults.standard.object(forKey: "dictOfSavedScreams") as! [String: String]?)!
        
        
//        let cell: SavedScreamsTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! SavedScreamsTableViewCell //było w buildzie 9
        let cell = tableView.dequeueReusableCell(withIdentifier: "SwipeSavedScreamsTableViewCell") as! SwipeSavedScreamsTableViewCell
        cell.savedTimeStamp?.text = "\(NSLocalizedString("Detected:", comment: "")) \(dictOfSavedScreams[audioFilenames[indexPath.row]] ?? "")"
        cell.setSavedChartInCell(audioData: dictOfAudioFloat[audioFilenames[indexPath.row]]!, points: 350)
        
        cell.delegate = self
        

        //        print(dictOfSavedScreams)
        //        print(audioFilenames[indexPath.row])
        //        print(dictOfSavedScreams[audioFilenames[indexPath.row]] ?? "")
        //        print(dictOfSavedScreams["424126560.m4a"])
        //        print(indexPath.row)
        //        print(audioFilenames.count)
        //        print(audioFilenames[indexPath.row])


        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     //   print(audioFilenames)
        print("You tapped cell number \(indexPath.row).")
        playScream2(audioFileName: audioFilenames[indexPath.row])
     //   print(audioFilenames[indexPath.row])
        
        
    }
    
    


    

    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if (editingStyle == UITableViewCell.EditingStyle.delete) {
//
//            deleteScream(deleteIndexPath: indexPath)
//
//        }
//    }

    

    
    
    func deleteScream(deleteIndexPath: IndexPath){
        
        // handle delete (by removing the data from your array and updating the tableview)
//        tableView.beginUpdates()
        print("indexpath: \(deleteIndexPath.row)")
        let fileManager = FileManager.default
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(audioFilenames[deleteIndexPath.row]) {
            let filePath = pathComponent.path
            do {
                try fileManager.removeItem(atPath: filePath)
                //                print("w try delete file: \(audioFilenames[indexPath.row])")
            }
            catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
            }
        }
        dictOfAudioFloat.removeValue(forKey: audioFilenames[deleteIndexPath.row])
        
        var dictOfSavedScreams = [String:String]()
        dictOfSavedScreams = (UserDefaults.standard.object(forKey: "dictOfSavedScreams") as! [String: String]?)!
 
        dictOfSavedScreams.removeValue(forKey: audioFilenames[deleteIndexPath.row])
        
        UserDefaults.standard.set(dictOfSavedScreams, forKey: "dictOfSavedScreams")
        
        audioFilenames.remove(at: deleteIndexPath.row)
        if audioFilenames.count == 0 {
            noSavedScreams.isHidden = false
        }
        
//        print("przed deleterows")
//        tableView.deleteRows(at: [deleteIndexPath], with: .left)      //tableView.deleteRows(at: [indexPath], with: .left)
//        print("po deleterows")
//        tableView.endUpdates()
        
        
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    

    
    
    

    
   
 
    
    
  
    
 
    
    func playScream2(audioFileName: String){


        var filePath: String!
        
        isPlayingScream = true
        playCounts += 1
        // print(playCounts)
        
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
//        print(path)
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(audioFileName) {
            filePath = pathComponent.path
//            print(filePath)
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                print("FILE AVAILABLE")
            } else {
                print("FILE NOT AVAILABLE")
            }
        } else {
            print("FILE PATH NOT AVAILABLE")
        }
        
        
        let urlFile = URL(fileURLWithPath: filePath)


        do {
            sound = try AVAudioPlayer(contentsOf: urlFile)
            sound.delegate = self
            sound.play()
        } catch let error{
            print(error)
        }

//        print("duration: \(sound.duration)")
        isPlayingScream = false
        
    }
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool){
        print("koniec grania")
        usleep(300000)
        if playCounts > 2{ //po ilu odtworzeniach ma być wyświetlony interstitial
            if interstitial.isReady {
                interstitial.present(fromRootViewController: self)
                playCounts = 0
            } else {
                print("Ad wasn't ready")
            }
        }
        self.isPlayingScream = false
        
    }
    
    
    
    func prepareAudioDataFloat(audioFileName: String) -> [Float]{
      //  print(audioFileName)
        var mixloop: AKAudioFile!
        
        do{
            try mixloop = AKAudioFile(readFileName: audioFileName, baseDir: .documents)
        } catch let error{
            print(error)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        timeStamp.insert(dateFormatter.string(from: Date()), at: 0)
//        print(date)
        
        return mixloop.floatChannelData![0]
        
        
    }
    

    

 
    
    func createAndLoadInterstitial() -> GADInterstitial {
//        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910") // testowy interistetial admob
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-8857410705016797/3847300079") //  moj admob
        
       interstitial.delegate = self
        interstitial.load(request)
        return interstitial
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial = createAndLoadInterstitial()
    }

    
   
    //toItem: bottomLayoutGuide
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        if #available(iOS 11.0, *) {
            view.addConstraints(
                [NSLayoutConstraint(item: bannerView,
                                    attribute: .bottom,
                                    relatedBy: .equal,
                                    toItem:  view.safeAreaLayoutGuide,
                                    attribute: .bottom,
                                    multiplier: 1,
                                    constant: 0),
                 NSLayoutConstraint(item: bannerView,
                                    attribute: .centerX,
                                    relatedBy: .equal,
                                    toItem: view,
                                    attribute: .centerX,
                                    multiplier: 1,
                                    constant: 0)
                ])
        } else {
            // Fallback on earlier versions
        }
        

    }
    
    
    

    

}


extension SavedScreamsViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {

        let share = SwipeAction(style: .default, title: nil) { action, indexPath in
            
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
            let url = NSURL(fileURLWithPath: path)
            let pathComponent = url.appendingPathComponent(self.audioFilenames[indexPath.row])
            let fileName = pathComponent!
//            print("filename full path: \(fileName)")
            
//            let url = NSURLfileURL(withPath:fileName)
            
            let activityViewController = UIActivityViewController(activityItems: [NSLocalizedString("Detected by ScreamTracker app", comment: ""), fileName] , applicationActivities: nil)
            
            DispatchQueue.main.async {
                
                self.present(activityViewController, animated: true, completion: nil)
            }
            
            
//            let text = "Be fabulous with FAB app and join our Fashion Advisory Board. Download it now from http://toappsto.re/fabapp/"
//            let textToShare = [ text ]
//            let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
//            activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
//
//            //        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.mail, UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.message ,UIActivity.ActivityType.postToTwitter]
//
//            self.present(activityViewController, animated: true, completion: nil)
            
            
        
            
        }
            configure(action: share, with: .share)
            
            let delete = SwipeAction(style: .destructive, title: nil) { action, indexPath in
                self.deleteScream(deleteIndexPath: indexPath)
//                tableView.deleteRows(at: [indexPath], with: .left)
            }
            delete.image = UIImage(named: "delete")
        print("jaki mamy buttondisplaymode? -> \(buttonDisplayMode)")
            configure(action: delete, with: .delete)
            
//            let cell = tableView.cellForRow(at: indexPath) as! SwipeSavedScreamsTableViewCell
//            let closure: (UIAlertAction) -> Void = { _ in cell.hideSwipe(animated: true) }
//            let more = SwipeAction(style: .default, title: nil) { action, indexPath in
//                let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//                controller.addAction(UIAlertAction(title: "Reply", style: .default, handler: closure))
//                controller.addAction(UIAlertAction(title: "Forward", style: .default, handler: closure))
//                controller.addAction(UIAlertAction(title: "Mark...", style: .default, handler: closure))
//                controller.addAction(UIAlertAction(title: "Notify Me...", style: .default, handler: closure))
//                controller.addAction(UIAlertAction(title: "Move Message...", style: .default, handler: closure))
//                controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: closure))
//                self.present(controller, animated: true, completion: nil)
//            }
//            configure(action: more, with: .more)
        
            return [delete, share]
        
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = orientation == .left ? .selection : .destructive
        options.transitionStyle = defaultOptions.transitionStyle
        
        switch buttonStyle {
        case .backgroundColor:
            options.buttonSpacing = 11
        case .circular:
            options.buttonSpacing = 4
            options.backgroundColor = #colorLiteral(red: 0.9467939734, green: 0.9468161464, blue: 0.9468042254, alpha: 1)
        }
        
        return options
    }
    
    func configure(action: SwipeAction, with descriptor: ActionDescriptor) {
        action.title = descriptor.title(forDisplayMode: buttonDisplayMode)
        action.image = descriptor.image(forStyle: buttonStyle, displayMode: buttonDisplayMode)
        
        switch buttonStyle {
        case .backgroundColor:
            action.backgroundColor = descriptor.color
        case .circular:
            action.backgroundColor = .clear
            action.textColor = descriptor.color
            action.font = .systemFont(ofSize: 13)
            action.transitionDelegate = ScaleTransition.default
        }
    }
    
    
}
