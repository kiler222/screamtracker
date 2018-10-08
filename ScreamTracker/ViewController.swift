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

class ViewController: UIViewController, GADBannerViewDelegate, GADInterstitialDelegate, AVAudioPlayerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBAction func backToFirstViewController(_ sender: Any) {
    
//        timerForAverageDB.invalidate()
//        timerForAverageDB = nil
        stopAndBack()
        dismiss(animated: true, completion: nil)
    
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
      
//        do {
//            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
//            try AVAudioSession.sharedInstance().setActive(true)
//        } catch {
//            print(error)
//        }
        
        
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
        print("-----------")
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
       
        
//        sleep(5)
     //   print("Tracker ampluted -------------- \(tracker.amplitude)")
//        repeat {
//            //usleep(10000) //czekamy az zakończy się export pliku
//             print("Tracker ampluted -------------- \(tracker.amplitude)")
//            sleep(1)
//        } while tracker.amplitude == 0.0
//
        
       
        
      
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
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716" //testowy admob
//        bannerView.adUnitID = "ca-app-pub-8857410705016797/7011915857" // moj admob
        
        
        bannerView.rootViewController = self
        bannerView.load(request)
        bannerView.delegate = self
        
        
        interstitial = createAndLoadInterstitial()
        interstitial.delegate = self
        interstitial.load(request)

//        repeat {
//                        //usleep(10000) //czekamy az zakończy się export pliku
//                         print("Tracker ampluted -------------- \(tracker.amplitude)")
//                        sleep(1)
//                    } while tracker.amplitude == 0.0
 
//        startScreamTracker()
        
        
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
         isPlayingScream = false
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

    

    
    
    func setChart() {
        
        
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<daneDecybele.count {
            let dataEntry = ChartDataEntry(x: Double(i), y: daneDecybele[i])
            dataEntries.append(dataEntry)
        }
        
        let chartDataSet = LineChartDataSet(values: dataEntries, label: "dB")
        chartDataSet.colors = [UIColor.green]
        
        let chartData = LineChartData()
        
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.mode = .horizontalBezier
        chartDataSet.drawFilledEnabled = true
      //  chartDataSet.cubicIntensity = 0.1
        
        
        chartData.addDataSet(chartDataSet)
        chartData.setDrawValues(false)
        
        lineChartView.data = chartData
        
        
        
        
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        AudioKit.output = silence
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
        
    }
    
    
    @IBAction func screamTrackerButton(_ sender: UIButton) {
        
        startScreamTracker()
        
        
    }
    
    
    
    func startScreamTracker(){
        
        if isScreamTrackerRunning == false{
        
            
            do {
                try recorder.reset()
            } catch{
                print("Error reseting recorder")
            }
            
           // resetCharts()

            startScreamTrackerPlot() //updateUI
            screamDetectionTimer()
            isScreamTrackerRunning = true
            screamTrackerButton.setTitle("Stop Scream Tracker", for: .normal)
            do {
                try recorder.record()
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
        
        screamTrackerButton.setTitle("Start Scream Tracker", for: .normal)
        timerForDrawingPlot.invalidate()
        timerForDrawingPlot = nil
        timerForScreamDetection.invalidate()
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
        
//
        if recorder.isRecording {
            recorder.stop()
            }
//            tracker.detach()
      //  micMixer.detach()
//        mic.detach()
//        silence.detach()
//        player.detach()
        
        do {
            try AudioKit.stop()
        } catch {
            AKLog("AudioKit did not start!")
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
        usleep(200000)
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
    

    
    
    
    
    func resetCharts(){
      
        x = 0
    }
    
    @objc func calculateAverageDB() {
       
      //  print("w calculateAveragaDB")
        if tracker.amplitude != 0 {
         
        if averageCounter < 10 {
        tempAverageDB.append(70 + convertAmplitudeToDb(amp: tracker.amplitude))
            
            if tempAverageDB.count > 10 {
                tempAverageDB.remove(at: 0)
            }

            averageCounter += 1

        } else {
         //   print(tempAverageDB)
            averageDB = tempAverageDB.reduce(0, +) / tempAverageDB.count
            print("average: \(String(describing: averageDB))")
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
        averageLimit.label = String(format: "Average sound level", averageLimit.limit)
     //   averageLimit.label = String(format: "Average sound level %.f dB", averageLimit.limit)
     //   screamLimitLine.label = String(format: "+%.f dB", (screamLimitLine.limit-averageLimit.limit))
        screamLimitLine.label = String(format: "Scream level +%.fdB", (screamLimitLine.limit-averageLimit.limit))
        
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
         //   print(screamDetectionLevel, screamLimitLine.limit)
            
            isFirstRun = false
        }
        
//        print("detected: \(daneDecybele.last!) average limit: \(averageLimit.limit) scream limit: \(screamLimitLine.limit) detectionLimit: \(screamDetectionLevel)")
//        print(String(format: "detected: %.1f  average limit: %.1f  scream limit: %.1f detectionLimit: %.1f ", daneDecybele.last!, averageLimit.limit, screamLimitLine.limit, screamLimitLine.limit))
        
        
//        print("ile danych: \(daneDecybele.count)")
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
                        
                        endSample = Int(recorder.audioFile!.samplesCount)
                        audioFilenames.insert("screamFile\(numbersOfScreams).m4a", at: 0)
                        exportScreamFile(audioFileName: "screamFile\(numbersOfScreams).m4a", startSample: (startSample-33075), endSample: (endSample))
                        
                     //   addRowWithScream() // odejmowałem 11025 i dodawałem 22050
                        
                        
                        numbersOfScreams += 1
                        
                    oneExtraStepWithoutScream = 0
                    }
                    
//                    print("krzyk < 70 i screamDetected == false")
                    
                }
            }
            
    
        }
        
        
    }

    
    
    func addRowWithScream(){
        
        
        let indexPath = IndexPath(row: 0, section:0)
    //    datas.insert("\(Date())", at: indexPath.row)                 // inserting default value (I'm inserting ""; )
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
        
        //        view.addConstraints(
//            [NSLayoutConstraint(item: bannerView,
//                                attribute: .bottom,
//                                relatedBy: .equal,
//                                toItem: view.safeAreaLayoutGuide,
//                                attribute: .top,
//                                multiplier: 1,
//                                constant: 0),
//             NSLayoutConstraint(item: bannerView,
//                                attribute: .centerX,
//                                relatedBy: .equal,
//                                toItem: view,
//                                attribute: .centerX,
//                                multiplier: 1,
//                                constant: 0)
//            ])
//
    }
    
    
    
    //MARK: not used func
    
//    func exportFile(){
//
//        tape = recorder.audioFile!
//        player.load(audioFile: tape)
//
//
//        if let _ = player.audioFile?.duration {
//            recorder.stop()
//            tape.exportAsynchronously(name: "TempTestFile.m4a",
//                                      baseDir: .documents,
//                                      exportFormat: .m4a) {_, exportError in
//                                        if let error = exportError {
//                                            print("Export Failed \(error)")
//                                        } else {
//                                            print("Export succeeded")
//                                        }
//            }
//
//
//
//
//        }
//
//        usleep(300000) //czekamy az zakończy się export pliku
//
//        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
//        let url = NSURL(fileURLWithPath: path)
//        if let pathComponent = url.appendingPathComponent("TempTestFile.m4a") {
//            let filePath = pathComponent.path
//            let fileManager = FileManager.default
//            if fileManager.fileExists(atPath: filePath) {
//                print("FILE AVAILABLE")
//            } else {
//                print("FILE NOT AVAILABLE")
//            }
//        } else {
//            print("FILE PATH NOT AVAILABLE")
//        }
//
//        let recordedDuration = player != nil ? player.audioFile?.duration  : 0
//        print(recordedDuration!)
//
//
//    }
    
/*    func drawWaveformChart(audioFileName: String, points: Int){
        var mixloop: AKAudioFile!
        
        do{
            try mixloop = AKAudioFile(readFileName: audioFileName, baseDir: .documents)
            //           print("w mixloopie")
        } catch let error{
            //           print("error po catchu")
            print(error)
        }
        
        setRecordedSessionChart(audioData: (mixloop.floatChannelData![0]), points: points)
        
        
        
    }
 */
    
 /*
    func setRecordedSessionChart(audioData: [Float], points: Int) {
        
        
        
        var dataEntries: [ChartDataEntry] = []
        
        print(audioData.count)
        
        for i in 0..<audioData.count {
            
            if i % (audioData.count / (points)) == 0{
                
                let dataEntry = ChartDataEntry(x: Double(i), y: Double(audioData[i]*10000))
                dataEntries.append(dataEntry)
            }
            
        }
        
        
        
        
        
        
        let chartDataSet = LineChartDataSet(values: dataEntries, label: "dB")
        chartDataSet.colors = [UIColor.red]
        
        let chartData = LineChartData()
        
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.mode = .cubicBezier
        chartDataSet.drawFilledEnabled = true
        //  chartDataSet.cubicIntensity = 0.1
        
        
        chartData.addDataSet(chartDataSet)
        chartData.setDrawValues(false)
        
        recordedSessionChartView.data = chartData
        recordedSessionChartView.xAxis.drawGridLinesEnabled = false
        recordedSessionChartView.xAxis.drawLabelsEnabled = false
        recordedSessionChartView.xAxis.labelPosition = .bottom
        recordedSessionChartView.xAxis.axisLineColor = .clear
        recordedSessionChartView.leftAxis.drawGridLinesEnabled = false
        recordedSessionChartView.leftAxis.drawLabelsEnabled = false
        recordedSessionChartView.rightAxis.drawLabelsEnabled = false
        recordedSessionChartView.rightAxis.drawGridLinesEnabled = false
        //        recordedSessionChartView.rightAxis.axisMaximum = 120
        //        recordedSessionChartView.rightAxis.axisMinimum = 30
        recordedSessionChartView.rightAxis.axisLineColor = .white
        //        recordedSessionChartView.leftAxis.axisMaximum = 120
        //        recordedSessionChartView.leftAxis.axisMinimum = 30
        recordedSessionChartView.leftAxis.axisLineColor = .white
        //   //   recordedSessionChartView.leftAxis.calculate(min: -0.001, max: 0.001)
        recordedSessionChartView.legend.enabled = false
        //    //  recordedSessionChartView.rightAxis.calculate(min: -0.001, max: 0.001)
        recordedSessionChartView.chartDescription?.enabled = false
        //        recordedSessionChartView.setScaleEnabled(false)
        
        recordedSessionChartView.frame = CGRect(x: 0, y: 210, width: view.frame.width , height: 85)
        
    }
*/
    

}
