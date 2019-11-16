//
//  ViewController.swift
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


protocol PassSavedFiles {
    func mySavedFiles(dictForSavedScreams : [String : String])
}



class ViewController: UIViewController, GADBannerViewDelegate, GADInterstitialDelegate, AVAudioPlayerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var delegate : PassSavedFiles?
    let hasWeaponOfMassDescrtruction : Bool = true
    
    var isSwipeRightEnabled = true
    var defaultOptions = SwipeOptions()
    var buttonStyle: ButtonStyle = .backgroundColor
    var buttonDisplayMode: ButtonDisplayMode = .imageOnly
    
    @IBAction func backToFirstViewController(_ sender: Any) {
    
//        if delegate != nil {
//            delegate?.mySavedFiles(dictForSavedScreams: dictForSavedScreams)
//        }
        
        
        if (tagsForHidden.count != audioFilenames.count) {
        let alert = UIAlertController(title: NSLocalizedString("Stop tracking screams?", comment: ""), message: NSLocalizedString("You lost your unsaved screams.", comment: ""), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { action in
            print("koniec trackingu")
        

            
             self.stopAndBack()
             self.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
        } else {
            

            
            self.stopAndBack()
            self.dismiss(animated: true, completion: nil)
            
        }
        

       
    
    }
    
    
 
    
    
    
    @IBOutlet weak var tableView: UITableView!
    let cellReuseIdentifier = "ScreamTableViewCell"
    

    
    @IBOutlet weak var lineChartView: LineChartView!
    
    
    @IBOutlet weak var averageField: UILabel!
    
    @IBOutlet weak var screamLevelField: UILabel!
    
    
    var datas = [String]()
    var duration = [Double]()
    var timeStamp = [String]()
    
    var months: [String]!
    var x: Int = 0 //counter do uzupełniania wykresu próbek
    var daneDecybele: [Double] = []
    var isFirstRun = true
    var isFirstTimeToSetScream = true
    var pierwszyRaz = 0
    
    var dictOfAudioFloat = [String:[Float]]()
    
    var dictForSavedScreams = [String : String]()
    
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
    var tagsForHidden: [String] = []
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
    
    let mic = AKMicrophone()
    
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
      
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let documentDirectory = URL(fileURLWithPath: path)
        print(documentDirectory)
        
        // This view controller itself will provide the delegate methods and row data for the table view.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = .clear
        tableView.rowHeight = 90;
        
        
//        print("które wejscie: \(pierwszyRaz)")
//        pierwszyRaz += 1
//
    //    mic = AKMicrophone()
        
        AKSettings.audioInputEnabled = true
        micMixer = AKMixer(mic)
        
        tracker = AKFrequencyTracker(micMixer)
        silence = AKBooster(tracker, gain: 0)
//        print("-----------")
     //   usleep(200000)
        // tutaj było startCalculatingAverageDB()
        
        startCalculatingAverageDB()
        
        
        // Clean tempFiles !
        AKAudioFile.cleanTempDirectory()
        
        // Session settings
        AKSettings.bufferLength = .medium
        
        do {
            try AKSettings.setSession(category: .playAndRecord, with: .defaultToSpeaker)
        } catch {
            AKLog("Could not set session category.")
        }
        
     
        
        AKSettings.defaultToSpeaker = true
        
        
        recorder = try? AKNodeRecorder(node: micMixer)
        if let file = recorder.audioFile {
            player = AKPlayer(audioFile: file)
        }
       
                AudioKit.output = silence
                do {
                    try AudioKit.start()
                    print("PJ audiokit started")
                } catch {
                    AKLog("AudioKit did not start!")
                }
        
        
        averageLimit.lineColor = .green
        averageLimit.lineWidth = 1
        averageLimit.drawLabelEnabled = false
        
        
        screamLimitLine.lineWidth = 1.5
        screamLimitLine.drawLabelEnabled = true
        
       averageLimit.labelPosition = .leftTop
        averageLimit.valueFont = .systemFont(ofSize: 10, weight: .light)
        
//        averageLimit.valueTextColor = .green
        
        screamLimitLine.valueFont = .systemFont(ofSize: 12, weight: .light)
        
        

        lineChartView.rightAxis.addLimitLine(screamLimitLine)
//        lineChartView.rightAxis.addLimitLine(averageLimit) //do rysowanie lini ze uśrednionymi wartościami DB
        
        lineChartView.noDataText = ""
        lineChartView.xAxis.drawGridLinesEnabled = false
        lineChartView.xAxis.drawLabelsEnabled = false
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.axisLineColor = .clear
        lineChartView.leftAxis.drawGridLinesEnabled = false
        lineChartView.leftAxis.drawLabelsEnabled = false
        lineChartView.rightAxis.drawLabelsEnabled = false
        lineChartView.rightAxis.drawGridLinesEnabled = true
        lineChartView.rightAxis.gridLineWidth = 0.5
       
        lineChartView.rightAxis.axisLineColor = .white
        lineChartView.leftAxis.axisMaximum = 100
        lineChartView.leftAxis.axisMinimum = 0
        lineChartView.rightAxis.axisMaximum = 100 // zmienić na 100
        lineChartView.rightAxis.axisMinimum = 0
        
        lineChartView.leftAxis.axisLineColor = .white
        lineChartView.legend.enabled = false
        lineChartView.chartDescription?.enabled = false
        lineChartView.setScaleEnabled(false)
  //      lineChartView.frame.size.width = view.frame.size.width
       // lineChartView.frame.size.height = 200
    //    lineChartView.frame.origin.x = 0
       
       
        //  request.testDevices = ["kGADSimulatorID", "b0aff17d3218b314d602d3ab5f425852"]
       
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

       
        ProgressHUD.show()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            self.startScreamTracker()
        })
        
        
    }
    
    //MARK: pan gesture
    
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
//        let translation = recognizer.translation(in: lineChartView)
        let touchPointY = recognizer.location(in: lineChartView).y
         isPlayingScream = true
        
        
        
                    if Double((142 - 13 - Double(touchPointY))*100 / (142-13)) > averageLimit.limit + 3 && Double((142 - 13 - Double(touchPointY))*100 / (142-13)) < 95 {
                        
                    
                    
                    screamLimitLine.limit = Double((142 - 13 - Double(touchPointY))*100 / (142-13))

                        isScreamLimitSetAverage = false
                    } else if Double((142 - 13 - Double(touchPointY))*100 / (142-13)) < averageLimit.limit + 3 {
                        screamLimitLine.limit = averageLimit.limit + 3
//                        print("zjechane poniżej averageDB")
                        isScreamLimitSetAverage = true
                        
                    } else {
                        screamLimitLine.limit = 94.9
                        isScreamLimitSetAverage = false
//                        print("wjechane powyzej 95")
                    }
                    
        
        
        recognizer.setTranslation(CGPoint.zero, in: lineChartView)
        screamDetectionLevel = Double(screamLimitLine.limit)
        
        if isFirstTimeToSetScream == true{
        screamLimitLine.label = NSLocalizedString("Set a scream level", comment: "")
            isFirstTimeToSetScream = false
        
        }
        
        
        
        isPlayingScream = false
    }

    
    
    //MARK: tableviewcell
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("ile wierszy: \(dictOfAudioFloat.keys.count)")
        return dictOfAudioFloat.keys.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell: ScreamTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! ScreamTableViewCell
        
//        cell.timeStamp?.text = String(format: "Duration: %.1f", duration[indexPath.row])
        
        cell.timeStamp?.text = "\(NSLocalizedString("Detected:", comment: "")) \(timeStamp[indexPath.row])"
     
        cell.setChartInCell(audioData: dictOfAudioFloat[audioFilenames[indexPath.row]]!, points: 350)
        
        cell.delegate = self
        
        let cellAudioButton = UIButton(type: .custom)
        cellAudioButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        cellAudioButton.addTarget(self, action: #selector(ViewController.accessoryButtonTapped(sender:)), for: .touchUpInside)
        cellAudioButton.setImage(UIImage(named: "save"), for: .normal)
        cellAudioButton.contentMode = .scaleAspectFit
        cellAudioButton.tag = indexPath.row
        print("ustawiony cell.sender.tag: \(cellAudioButton.tag)")
        if tagsForHidden.contains(audioFilenames[indexPath.row]){
            cellAudioButton.isHidden = true
        }
//        print("indexpath.row: \(indexPath.row)")
        cell.accessoryView = cellAudioButton as UIView
        
        
        return cell
    }
    

    
    
    @objc func accessoryButtonTapped(sender : UIButton){
        print("sender.tag: \(sender.tag)")
        print("audiofilenames count: \(audioFilenames.count)")
        print("audifilnams array: \(audioFilenames)")
    
        let number = Int.random(in: 100000000 ... 999999999)
                        do {
                            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                            let documentDirectory = URL(fileURLWithPath: path)

                              let originPath = documentDirectory.appendingPathComponent(audioFilenames[sender.tag])
                            print(originPath)
//                            let destinationPath = documentDirectory.appendingPathComponent("saved\(audioFilenames[sender.tag])")
                            let destinationPath = documentDirectory.appendingPathComponent("\(number).m4a")
                            print(destinationPath)
                            try FileManager.default.copyItem(at: originPath, to: destinationPath)
                        } catch {
                            print(error)
                        }
        
        print(timeStamp[sender.tag])
        
//        dictForSavedScreams[audioFilenames[sender.tag]] = timeStamp[sender.tag]
        
        var tempDictOfSavedScreams =  UserDefaults.standard.object(forKey: "dictOfSavedScreams") as! [String:String]?
        
        tempDictOfSavedScreams?["\(number).m4a"] = timeStamp[sender.tag]
        
        UserDefaults.standard.set(tempDictOfSavedScreams, forKey: "dictOfSavedScreams")
//        print(UserDefaults.standard.object(forKey: "dictOfSavedScreams"))
        
        tagsForHidden.append(audioFilenames[sender.tag])
        sender.isHidden = true
        ProgressHUD.showSuccess("\(NSLocalizedString("Scream saved!", comment: ""))")
        
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     //   print(audioFilenames)
        print("You tapped cell number \(indexPath.row).")
        stopScreamTrackerPlot()
        playScream2(audioFileName: audioFilenames[indexPath.row])
        print(audioFilenames[indexPath.row])
        
        
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
            

        }
    }

    
    func deleteScream(deleteIndexPath: IndexPath){
        
        // handle delete (by removing the data from your array and updating the tableview)
        
//        tableView.beginUpdates()
        print("kasuje taki plik: \(audioFilenames[deleteIndexPath.row])")
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
        
        print(tagsForHidden)
        if let index = tagsForHidden.index(of: audioFilenames[deleteIndexPath.row]) {
            tagsForHidden.remove(at: index)
        }
        print(tagsForHidden)
        
        print(dictOfAudioFloat.keys)
        dictOfAudioFloat.removeValue(forKey: audioFilenames[deleteIndexPath.row])
        audioFilenames.remove(at: deleteIndexPath.row)
        
        
        print(dictOfAudioFloat.keys)
//        tableView.deleteRows(at: [indexPath], with: .left)
//        tableView.endUpdates()
//        tableView.reloadData() //czy to dobrze?
//
        
    }
    
    
    func setChart() {
        
        
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<daneDecybele.count {
            let dataEntry = ChartDataEntry(x: Double(i), y: daneDecybele[i])
            dataEntries.append(dataEntry)
        }
        
        let chartDataSet = LineChartDataSet(values: dataEntries, label: "dB")
//        chartDataSet.colors = [UIColor.green.withAlphaComponent(0.33)]
        chartDataSet.colors = [UIColor(red: 0.54902, green: 0.917647, blue: 1, alpha: 0.7)]
        let chartData = LineChartData()
        
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.mode = .horizontalBezier
        chartDataSet.drawFilledEnabled = true
//        print(chartDataSet.fillColor)

        
     //   print(chartDataSet.fillColor.withAlphaComponent(<#T##alpha: CGFloat##CGFloat#>))
        
        
//        chartDataSet.fillAlpha = 1
        
        
      //  chartDataSet.cubicIntensity = 0.1
        
        
        chartData.addDataSet(chartDataSet)
        chartData.setDrawValues(false)
        
        lineChartView.data = chartData
        
        
        
        
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("PJ viewdidappear przed crashem????")
//        AudioKit.output = silence
//        do {
//            try AudioKit.start()
//        } catch {
//            AKLog("AudioKit did not start!")
//        }
        
    }
    
//    func viewWillDisappear() {
//    delegate.pass(data: "someData") //call the func in the previous vc
//    }
    
    
    @IBAction func screamTrackerButton(_ sender: UIButton) {
        ProgressHUD.show()

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
             self.startScreamTracker()
        })
        
        
       
        
    }
    
    
    
    func startScreamTracker(){
     //   print(">>>>>>>averageDB: \(String(describing: averageDB))")
        if isScreamTrackerRunning == false{
        
            
            do {
                try recorder.reset()
            } catch{
                print("Error reseting recorder")
            }
            
           // resetCharts()
           recorder.stop()
            
            ProgressHUD.dismiss()
            startScreamTrackerPlot() //updateUI
            
            isScreamTrackerRunning = true
         //   screamTrackerButton.setTitle("Stop Scream Tracker", for: .normal)
            do {
                try recorder.record()
                screamDetectionTimer()
            } catch {
                print("Errored recording.")
            }
            
        }
            
        else{
            stopScreamTrackerPlot()
        }
    }
    
   
    
    func exportScreamFile(audioFileName: String, startSample: Int, endSample: Int){
        
   //     usleep(100000) //czekamy żeby dograły się próbki jeśli do endSample coś dodajemy
        
        tape = recorder.audioFile!
        player.load(audioFile: tape)
        
       
        if let _ = player.audioFile?.duration {
           // recorder.stop()
            tape.exportAsynchronously(name: audioFileName, baseDir: .documents, exportFormat: .m4a, fromSample: Int64(startSample), toSample: Int64(endSample)) {_, exportError in
                
                print("PJ from: \(startSample), to: \(endSample), duration: \(self.player.audioFile?.duration)")
                                        if let error = exportError {
                                            print("Export Failed \(error.localizedDescription)")
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
        tableView.reloadData()
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(audioFileName) {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                print("FILE AVAILABLE")
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
    
    
    func startScreamTrackerPlot(){
        timerForDrawingPlot = Timer.scheduledTimer(timeInterval: 0.3,
                             target: self,
                             selector: #selector(ViewController.updateUI),
                             userInfo: nil,
                             repeats: true)

    }
    
    func screamDetectionTimer(){
        timerForScreamDetection = Timer.scheduledTimer(timeInterval: 0.3,
                                                   target: self,
                                                   selector: #selector(ViewController.screamDetection),
                                                   userInfo: nil,
                                                   repeats: true)
        
    }
    
    func startCalculatingAverageDB(){
        timerForAverageDB = Timer.scheduledTimer(timeInterval: 0.03,
                                                   target: self,
                                                   selector: #selector(ViewController.calculateAverageDB),
                                                   userInfo: nil,
                                                   repeats: true)
        
    }
    
    func stopScreamTrackerPlot(){
        
     //   screamTrackerButton.setTitle("Start Scream Tracker", for: .normal)
        if timerForDrawingPlot != nil {
            timerForDrawingPlot.invalidate()
        }
        timerForDrawingPlot = nil
        if timerForScreamDetection != nil{
            timerForScreamDetection.invalidate()
        }
        timerForScreamDetection = nil
//        timerForAverageDB.invalidate()
//        timerForAverageDB = nil
        
        isScreamTrackerRunning = false

    }
    
    func stopAndBack(){
       
        if timerForDrawingPlot != nil {
            timerForDrawingPlot.invalidate()
            timerForDrawingPlot = nil
        }
        
        if timerForScreamDetection != nil {
            timerForScreamDetection.invalidate()
            timerForScreamDetection = nil
        }
        
        if timerForAverageDB != nil {
            timerForAverageDB.invalidate()
            timerForAverageDB = nil
        }
        
        if recorder.isRecording {
            recorder.stop()
            }
    
        do {
            try AudioKit.stop()
        } catch {
            AKLog("AudioKit did not start!")
        }
        
        let fileManager = FileManager.default
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        
        
        for i in 0..<audioFilenames.count{
            if let pathComponent = url.appendingPathComponent(audioFilenames[i]) {
                let filePath = pathComponent.path
                do {
                    try fileManager.removeItem(atPath: filePath)
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
            }
        }
        
        
    }
    
    
 /*
    func playScream(audioFileName: String){
        var player: AKPlayer!
        var mixloop: AKAudioFile!
        
        
        isPlayingScream = true
        playCounts += 1
       // print(playCounts)
        
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        print(path)
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(audioFileName) {
            let filePath = pathComponent.path
            print(filePath)
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                print("FILE AVAILABLE")
            } else {
                print("FILE NOT AVAILABLE")
            }
        } else {
            print("FILE PATH NOT AVAILABLE")
        }
        
        do{
            try mixloop = AKAudioFile(readFileName: audioFileName, baseDir: .documents)
            

        } catch let error{
            print("error w play scream przy dotrycatch?")
            print(error)
        }

            player = AKPlayer(audioFile: mixloop)

            print("duration: \(mixloop.duration)")
         //   print("samples count: \(mixloop.samplesCount)")



            player.completionHandler = {
                
                print("ZAKONCZYLEM GRAC PLIK AUDIO!!!!!!!!!!!!!!!!!")
                Swift.print("completion callback has been triggered!")
                usleep(200000)
                if self.playCounts > 10{ //po ilu odtworzeniach ma być wyświetlony interstitial
                    if self.interstitial.isReady {
                        self.interstitial.present(fromRootViewController: self)
                        self.playCounts = 0
                    } else {
                        print("Ad wasn't ready")
                    }
                }
                self.isPlayingScream = false
                
                
        }
        
            player.isLooping = false
            player.buffering = .always
            AudioKit.output = player
           player.play()
        
        
        

        
        
    }
 */
    
    func playScream2(audioFileName: String){
        self.recorder.stop()
        
        //TODO - jak wiele razy klikam odtwarzanie plików to na "timerForScreamDetection.invalidate()" wywala Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value
        
        if timerForScreamDetection != nil {
            timerForScreamDetection.invalidate()
        }
        timerForScreamDetection = nil

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
//                print("FILE AVAILABLE")
            } else {
//                print("FILE NOT AVAILABLE")
            }
        } else {
            print("FILE PATH NOT AVAILABLE")
        }
        
        
        
        
        
        
        let urlFile = URL(fileURLWithPath: filePath)

//        print(filePath)
//        print(urlFile)

        do {
            try recorder.reset()
        } catch{
            print("Error reseting recorder")
        }
        
        // resetCharts()
        
//        ProgressHUD.dismiss()
//        startScreamTrackerPlot() //updateUI
//        screamDetectionTimer()
//        isScreamTrackerRunning = true
        //   screamTrackerButton.setTitle("Stop Scream Tracker", for: .normal)
        
        
        

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
      
        //        usleep(300000)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            if self.playCounts > 2{ //było ">2" - po ilu odtworzeniach ma być wyświetlony interstitial
                
                if self.interstitial.isReady {
                    self.interstitial.present(fromRootViewController: self)
                    self.playCounts = 0
                } else {
                    print("Ad wasn't ready")
                }
            } else {
                do{
                    try self.recorder.record()
                    startScreamTrackerPlot()
                    screamDetectionTimer()
                    
                } catch {
                    print("PJ blad recordingu")
                }
            
            }
        
//        })
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
//        dateFormatter.dateStyle = .short
//        dateFormatter.timeStyle = .short
        dateFormatter.dateFormat = "dd/MM/yy hh:mm:ss a"
        
        
        timeStamp.insert(dateFormatter.string(from: Date()), at: 0)
//        print(date)
        
        return mixloop.floatChannelData![0]
        
//        setRecordedSessionChart(audioData: (mixloop.floatChannelData![0]), points: points)
        
        
    }
    

    
    
    
    
    func resetCharts(){
      
        x = 0
    }
    
    @objc func calculateAverageDB() {
       
      //  print("w calculateAveragaDB")
        if tracker.amplitude != 0 {
         
        if averageCounter < 10 {
        tempAverageDB.append(85 + convertAmplitudeToDb(amp: tracker.amplitude))
            
            if tempAverageDB.count > 10 {
                tempAverageDB.remove(at: 0)
            }

            averageCounter += 1

        } else {
         //   print(tempAverageDB)
            averageDB = tempAverageDB.reduce(0, +) / tempAverageDB.count
         //   print("average: \(String(describing: averageDB))")
            averageCounter = 0
        
        }
        } else {
    //       print("w ifie że tracker.amplitue = 0")
        }
    }
    
    @objc func updateUI() {
        
        if x == 0 {
            daneDecybele.removeAll()
        }
        
        if x < chartPoints{ //ilość punktów na wykresie
            
            for _ in x..<chartPoints {
            daneDecybele.append(averageDB) //110 + convertAmplitudeToDb(amp: tracker.amplitude))
            }

            x += chartPoints
            
//            if isFirstRun == true {
//                print("w first runie")
//                screamDetectionLevel = (limitAverageDB.reduce(0, +)/limitAverageDB.count + 20)
//                screamLimitLine.limit = screamDetectionLevel
//                print(screamDetectionLevel, screamLimitLine.limit)
//
//                isFirstRun = false
//            }
            
        } else {
            daneDecybele.remove(at: 0)
            daneDecybele.append(averageDB) //110 + convertAmplitudeToDb(amp: tracker.amplitude))
            
        }
        
//        print("updatingUI: \(daneDecybele.last!)")
       limitAverageDB.append(averageDB)
        if limitAverageDB.count > chartPoints{
            limitAverageDB.remove(at: 0)
        }
        
//        print("average DB: \(averageDB)")

        averageLimit.limit = (limitAverageDB.reduce(0, +)/limitAverageDB.count)
        averageLimit.label = String(format: NSLocalizedString("Average sound level", comment: ""), averageLimit.limit)
     //   averageLimit.label = String(format: "Average sound level %.f dB", averageLimit.limit)
     //   screamLimitLine.label = String(format: "+%.f dB", (screamLimitLine.limit-averageLimit.limit))
      
//        screamLimitLine.label = String(format: "Scream level +%.fdB", (screamLimitLine.limit-averageLimit.limit))
      
       
        
        
        
        if isScreamLimitSetAverage == true {
                screamLimitLine.limit = averageLimit.limit + 3
            screamDetectionLevel = Double(screamLimitLine.limit)
        }
//
     //   if isPlayingScream == false {
            if screamLimitLine.limit-averageLimit.limit < 2 {
                screamLimitLine.limit = averageLimit.limit + 3
                screamDetectionLevel = Double(screamLimitLine.limit)
            }
//        }
        
        if isFirstRun == true {
          //  print("av limi +20: \(averageLimit.limit + 20)")
                
            screamDetectionLevel = averageLimit.limit + 6
            screamLimitLine.limit = screamDetectionLevel
            screamLimitLine.label = NSLocalizedString("Scream level", comment: "")
            
         //   print(screamDetectionLevel, screamLimitLine.limit)
            
            isFirstRun = false
        } 
//        print("detected: \(daneDecybele.last!) average limit: \(averageLimit.limit) scream limit: \(screamLimitLine.limit) detectionLimit: \(screamDetectionLevel)")
//        print(String(format: "detected: %.1f  average limit: %.1f  scream limit: %.1f detectionLimit: %.1f ", daneDecybele.last!, averageLimit.limit, screamLimitLine.limit, screamLimitLine.limit))
        
        
//        print("ile danych: \(daneDecybele.count)")
        
        
        averageField.text = String(format: "\(NSLocalizedString("Average level:", comment: "")) %.f dB", averageLimit.limit)
        screamLevelField.text = String(format: "\(NSLocalizedString("Scream level:", comment: "")) +%.f dB", (screamDetectionLevel - averageLimit.limit))

        
        setChart()
        
    }


    @objc func screamDetection() {
        //     print("Gain: \(tracker.amplitude) dB: \(100 + convertAmplitudeToDb(amp: tracker.amplitude))")
        if isPlayingScream == false {
            

            
            if daneDecybele.last! > screamDetectionLevel { ///!!!!!!!!!!!! zmienić żeby wykrywać scream
                
                if screamDetected == false {
                    
                    screamDetected = true
                    oneExtraStepWithoutScream = 1
                    startSample = Int(recorder.audioFile!.samplesCount)
                    
                    print("detected: \(daneDecybele.last!)")
//                    print("próbka: \(recorder.audioFile!.samplesCount)")
//                    print("krzyk > 70 i screamDetected == false")
                }
                else{
//                    print("krzyk > 70 i screamDetected == true")
                }
                
            }
            else {
                if screamDetected == true {
//                    print("krzyk < 70 i screamDetected == true")
                   screamDetected = false
                    
                }
                else{
                    
                    if oneExtraStepWithoutScream == 1 {
                        
                        print("\n\(oneExtraStepWithoutScream)\n")
                        oneExtraStepWithoutScream -= 1
                        
                        if oneExtraStepWithoutScream == 0{
                            endSample = Int(recorder.audioFile!.samplesCount)
                            
                            if ((startSample - 33075) < endSample ) {
                                
                                audioFilenames.insert("screamFile\(numbersOfScreams).m4a", at: 0)
                                exportScreamFile(audioFileName: "screamFile\(numbersOfScreams).m4a", startSample: (startSample-33075), endSample: (endSample))
                                numbersOfScreams += 1
                                } else {
                                print("PJ ERROR start sample: \(startSample - 33075), end: \(endSample!)")
                                screamDetected = false
                            }
                        
                        
                        
                        }
                        
                    }

                    
                }
            }
            
    
        }
        
        
    }

    
    
    func addRowWithScream(){
        
        
        let indexPath = IndexPath(row: 0, section:0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        
        
    }
    
    func convertAmplitudeToDb(amp: Double) -> Double{
        return 20.0 * log10(amp)
    }
    
   
    

    @IBAction func runInterstitial(_ sender: UIButton) {
    
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        } else {
            print("Ad wasn't ready")
        }
    
    }
    
    
    func createAndLoadInterstitial() -> GADInterstitial {
//        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910") // testowy interistetial admob
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-8857410705016797/3847300079") //  moj admob
        
        interstitial.delegate = self
        interstitial.load(request)
        return interstitial
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        print("PJ cancelowana reklama")
        do {
            try recorder.record()
            startScreamTrackerPlot()
        } catch {
            print("Errored recording.")
        }
        interstitial = createAndLoadInterstitial()
        screamDetectionTimer()
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



extension ViewController: SwipeTableViewCellDelegate {
    
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
            DispatchQueue.main.async {
                
                tableView.reloadData()
            }
            //                tableView.deleteRows(at: [indexPath], with: .left)
        }
        delete.image = UIImage(named: "delete")
//        print("jaki mamy buttondisplaymode? -> \(buttonDisplayMode)")
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
