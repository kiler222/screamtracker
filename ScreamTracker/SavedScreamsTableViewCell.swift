//
//  SavedScreamsTableViewCell.swift
//  ScreamTracker
//
//  Created by kiler on 11.10.2018.
//  Copyright © 2018 kiler. All rights reserved.
//

import UIKit
import Charts


class SavedScreamsTableViewCell: UITableViewCell {

    @IBOutlet weak var savedChartView: LineChartView!
    
    @IBOutlet weak var savedTimeStamp: UILabel!
    
    func setSavedChartInCell(audioData: [Float], points: Int) {
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<audioData.count {
            
            if i % (audioData.count / (points)) == 0{
                
                let dataEntry = ChartDataEntry(x: Double(i), y: Double(audioData[i]*10000))
                dataEntries.append(dataEntry)
            }
        }
        
        let chartDataSet = LineChartDataSet(values: dataEntries, label: "dB")
        chartDataSet.colors = [UIColor.red.withAlphaComponent(0.6)]
        
        let chartData = LineChartData()
        
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.mode = .cubicBezier
        chartDataSet.drawFilledEnabled = true
        chartDataSet.fillColor = .red
        chartDataSet.fillAlpha = 0.6
        chartDataSet.lineWidth = 2
        //  chartDataSet.cubicIntensity = 0.1
        chartData.addDataSet(chartDataSet)
        chartData.setDrawValues(false)
        savedChartView.data = chartData
        //     screamChartView.backgroundColor = .gray
        savedChartView.xAxis.drawGridLinesEnabled = false
        savedChartView.xAxis.drawLabelsEnabled = false
        savedChartView.xAxis.labelPosition = .bottom
        savedChartView.xAxis.axisLineColor = .clear
        savedChartView.leftAxis.drawGridLinesEnabled = false
        savedChartView.leftAxis.drawLabelsEnabled = false
        savedChartView.rightAxis.drawLabelsEnabled = false
        savedChartView.rightAxis.drawGridLinesEnabled = false
        savedChartView.rightAxis.axisLineColor = .clear
        savedChartView.leftAxis.axisLineColor = .clear
        savedChartView.legend.enabled = false
        savedChartView.chartDescription?.enabled = false
        
        
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
