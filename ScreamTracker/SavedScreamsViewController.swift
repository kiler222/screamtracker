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

class SavedScreamsViewController: UIViewController, GADBannerViewDelegate, GADInterstitialDelegate, AVAudioPlayerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBAction func backtoFirstViewController(_ sender: Any) {
    
        self.dismiss(animated: true, completion: nil)
        
    }

    
    
    
    @IBOutlet weak var tableView: UITableView!
    let cellReuseIdentifier = "ScreamTableViewCell"
    
    
    @IBOutlet weak var screamTrackerButton: UIButton!
    
    @IBOutlet weak var drawWaveform: UIView!
    
    
    @IBOutlet weak var lineChartView: LineChartView!
    
    
    @IBOutlet weak var recordedSessionChartView: LineChartView!
    
    var datas = [String]()
    var duration = [Double]()
    var timeStamp = [String]()
    
    var months: [String]!
    var x: Int = 0 //counter do uzupełniania wykresu próbek
    var daneDecybele: [Double] = []
    var isFirstRun = true
    
    var pierwszyRaz = 0
    
    var dictOfAudioFloat = [String:[Float]]()
    
    var oneExtraStepWithoutScream: Int = 0
    var exportFinished: Bool = false
    var isScreamTrackerRunning: Bool = false
    
    var isPlayingScream: Bool = false
    var screamDetectionLevel: Double = 70
    
    var isScreamLimitSetAverage = false
    
    var delta: Float = 0.0
    var touchedPointY: Double!
    
    var numbersOfScreams: Int = 0
    var audioFilenames: [String] = []
    var playCounts = 0 //ile razy został odtworzony dzwiek, potrzebne do wyświetlania reklam interstitial
    
    var averageCounter = 0
    
    var tempAverageDB: [Double] = []
    var limitAverageDB: [Double] = []
    var averageLimit = ChartLimitLine()
    var screamLimitLine = ChartLimitLine()
    
    var averageDB: Double!
    
    var screamDetected: Bool = false
    var startSample: Int!
    var endSample: Int!
    
    var audioDataArray: [Float] = []
    
    var bannerView: GADBannerView!
    let request = GADRequest()
    
    var interstitial: GADInterstitial!
    
    var timerForDrawingPlot: Timer!
    var timerForScreamDetection: Timer!
    var timerForAverageDB: Timer!
    
  //  let mic = AKMicrophone()
    
    let chartPoints: Int = 150
    
    var tracker: AKFrequencyTracker!
    var silence: AKBooster!
    var clipRecoder: AKClipRecorder!
    var recorder: AKNodeRecorder!
    var micMixer: AKMixer!
    var player: AKPlayer!
    var tape: AKAudioFile!
    
    var sound: AVAudioPlayer!
  

    
    
    
    
  
//    @IBAction func crashButtonTapped(_ sender: AnyObject) {
//        Crashlytics.sharedInstance().crash()
//    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        
        
        // This view controller itself will provide the delegate methods and row data for the table view.
 
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.separatorColor = .clear
//        tableView.rowHeight = 90;
//
       
       // AKSettings.audioInputEnabled = true
      //  micMixer = AKMixer(mic)
        
       // tracker = AKFrequencyTracker(micMixer)
       // silence = AKBooster(tracker, gain: 0)
        
        
        
        // Clean tempFiles !
     //   AKAudioFile.cleanTempDirectory()
        
        // Session settings
//        AKSettings.bufferLength = .medium
//        
//        do {
//            try AKSettings.setSession(category: .playAndRecord, with: .defaultToSpeaker)
//        } catch {
//            AKLog("Could not set session category.")
//        }
//        
//     
//        
//        AKSettings.defaultToSpeaker = true
//        
//        
//        recorder = try? AKNodeRecorder(node: micMixer)
//        if let file = recorder.audioFile {
//            player = AKPlayer(audioFile: file)
//        }
//       

     
       
        //  request.testDevices = ["kGADSimulatorID", "b0aff17d3218b314d602d3ab5f425852"]
       
        request.testDevices = ["kGADSimulatorID", "b0aff17d3218b314d602d3ab5f425852"]
        
        // In this case, we instantiate the banner with desired ad size.
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716" //testowy admob
//        bannerView.adUnitID = "ca-app-pub-8857410705016797/7011915857" // moj admob
        
        
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
            print(fileURLs.count)
       
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [])
           // print(directoryContents)
            
            let testFiles = directoryContents.filter{ $0.pathExtension == "m4a" }
            print("testowe urls:",testFiles)
            let testFileNames = testFiles.map{ $0.deletingPathExtension().lastPathComponent }

            for i in 0 ..< testFileNames.count {
                print(testFileNames[i])
            }
//            print("testowe pliki w liście:", testFileNames)

            
            
//            let enumerator = FileManager.default.enumerator(atPath: Bundle.main.resourcePath!)
//            let filePaths = enumerator?.allObjects as! [String]
//            let txtFilePaths = filePaths.filter{$0.contains(".m4a")}
//            for txtFilePath in txtFilePaths{
//                print(txtFilePath)
                //Here you get each text file path present in folder
                //Perform any operation you want by using its path
//            }
            
            
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
        let cell: ScreamTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! ScreamTableViewCell
        
//        cell.timeStamp?.text = String(format: "Duration: %.1f", duration[indexPath.row])
        
        cell.timeStamp?.text = "Detected: \(timeStamp[indexPath.row])"
     
        cell.setChartInCell(audioData: dictOfAudioFloat[audioFilenames[indexPath.row]]!, points: 350)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     //   print(audioFilenames)
        print("You tapped cell number \(indexPath.row).")
        playScream2(audioFileName: audioFilenames[indexPath.row])
     //   print(audioFilenames[indexPath.row])
        
        
    }
    
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: lineChartView)
            
          //  print("dotkniety y: \(position.y) limitline: \(screamLimitLine.limit)")
           
            touchedPointY = Double(position.y)
            
       //     print(screamLimitLine.limit)
        }
    }
    
    

    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCell.EditingStyle.delete) {
            
            // handle delete (by removing the data from your array and updating the tableview)
         tableView.beginUpdates()
            print(dictOfAudioFloat.keys)
            dictOfAudioFloat.removeValue(forKey: audioFilenames[indexPath.row])
            audioFilenames.remove(at: indexPath.row)
            
         print(dictOfAudioFloat.keys)
            tableView.deleteRows(at: [indexPath], with: .left)
            tableView.endUpdates()
        }
    }

    

    
    
   
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
     
        
    }
    
    

    
    
    

    
   
    
    func exportScreamFile(audioFileName: String, startSample: Int, endSample: Int){
        
   //     usleep(100000) //czekamy żeby dograły się próbki jeśli do endSample coś dodajemy
        
        tape = recorder.audioFile!
        player.load(audioFile: tape)
        
       
        if let _ = player.audioFile?.duration {
           // recorder.stop()
            tape.exportAsynchronously(name: audioFileName, baseDir: .documents, exportFormat: .m4a, fromSample: Int64(startSample), toSample: Int64(endSample)) {_, exportError in
                                        if let error = exportError {
                                            print("Export Failed \(error)")
                                        } else {
                                            print("Export succeeded")
                                            self.dictOfAudioFloat[audioFileName] = self.prepareAudioDataFloat(audioFileName: audioFileName)
                                            self.exportFinished = true
                                            
                                        }
            }
      
            
        }
        
        
        repeat {
            usleep(10000) //czekamy az zakończy się export pliku
           
        } while exportFinished != true
        
        
        exportFinished = false
        addRowWithScream()
        
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(audioFileName) {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                print("FILE AVAILABLE")
                print(filePath)
                print(path)
                
                do {
                    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                    let documentDirectory = URL(fileURLWithPath: path)
                  
                      let originPath = documentDirectory.appendingPathComponent(audioFileName)
                    let destinationPath = documentDirectory.appendingPathComponent("test\(audioFileName)")
                    try FileManager.default.copyItem(at: originPath, to: destinationPath)
                } catch {
                    print(error)
                }
                
                
            } else {
                print("FILE NOT AVAILABLE")
            }
        } else {
            print("FILE PATH NOT AVAILABLE")
        }
        
   
        
    }
    
   
//    func callback(processedFile: AKAudioFile?, error: NSError?) {
    func callback(processedFile: AKAudioFile?, error: NSError?) {
            print("Export completed!")
        
        // Check if processed file is valid (different from nil)
        if let converted = processedFile {
            print("Export succeeded, converted file: \(converted.fileNamePlusExtension)")
            // Print the exported file's duration
            print("Exported File Duration: \(converted.duration) seconds")
            // Replace the file being played
          //  try? player.replace(file: converted)
        } else {
            // An error occurred. So, print the Error
            print("Error: \(String(describing: error?.localizedDescription))")
        }
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

//        print(filePath)
//        print(urlFile)


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
        if playCounts > 3{ //po ilu odtworzeniach ma być wyświetlony interstitial
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
        
        var mixloop: AKAudioFile!
        
        do{
            try mixloop = AKAudioFile(readFileName: audioFileName, baseDir: .documents)
        } catch let error{
            print(error)
        }
        
        //usleep(10000)
     //   print("ile próbek ma plik: \(mixloop.floatChannelData![0].count)")
    //    print("w preapre audio datafloat: \(mixloop.duration)")
        duration.insert(mixloop!.duration, at: 0)

//        timeStamp.insert(NSDate().timeIntervalSince1970, at: 0)
//        timeStamp.insert(String(Date()), at: 0)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        timeStamp.insert(dateFormatter.string(from: Date()), at: 0)
//        print(date)
        
        return mixloop.floatChannelData![0]
        
//        setRecordedSessionChart(audioData: (mixloop.floatChannelData![0]), points: points)
        
        
    }
    

    

    
    
    func addRowWithScream(){
        
        
        let indexPath = IndexPath(row: 0, section:0)
    //    datas.insert("\(Date())", at: indexPath.row)                 // inserting default value (I'm inserting ""; )
        tableView.insertRows(at: [indexPath], with: .automatic)
        
        
    }
    
    func convertAmplitudeToDb(amp: Double) -> Double{
        return 20.0 * log10(amp)
    }
    
   
    

    
    
    func createAndLoadInterstitial() -> GADInterstitial {
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910") // testowy interistetial admob
//        interstitial = GADInterstitial(adUnitID: "ca-app-pub-8857410705016797/3847300079") //  moj admob
        
//        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910") //testowy video interisitial admob
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
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem:  view,
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
        

    }
    
    
    

    

}
