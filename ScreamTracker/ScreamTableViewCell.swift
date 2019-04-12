//
//  ScreamTableViewCell.swift
//  ScreamTracker
//
//  Created by kiler on 19.09.2018.
//  Copyright © 2018 kiler. All rights reserved.
//

import UIKit
import Charts
import SwipeCellKit

class ScreamTableViewCell: SwipeTableViewCell {


    
    @IBOutlet weak var timeStamp: UILabel!
    
    
    @IBOutlet weak var screamChartView: LineChartView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    

    
    func setChartInCell(audioData: [Float], points: Int) {
        
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
//        print(chartDataSet.fillColor)
        
        screamChartView.data = chartData
   //     screamChartView.backgroundColor = .gray
        screamChartView.xAxis.drawGridLinesEnabled = false
        screamChartView.xAxis.drawLabelsEnabled = false
        screamChartView.xAxis.labelPosition = .bottom
        screamChartView.xAxis.axisLineColor = .clear
        screamChartView.leftAxis.drawGridLinesEnabled = false
        screamChartView.leftAxis.drawLabelsEnabled = false
        screamChartView.rightAxis.drawLabelsEnabled = false
        screamChartView.rightAxis.drawGridLinesEnabled = false
        screamChartView.rightAxis.axisLineColor = .clear
        screamChartView.leftAxis.axisLineColor = .clear
        screamChartView.legend.enabled = false
        screamChartView.chartDescription?.enabled = false

        
    }

}
