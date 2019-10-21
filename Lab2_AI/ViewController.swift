//
//  ViewController.swift
//  Lab2_AI
//
//  Created by Alexandr on 23/09/2019.
//  Copyright © 2019 Alexandr. All rights reserved.
//

import Cocoa
import Charts

class ViewController: NSViewController {
    
    typealias Function = (Double) -> Double

    @IBOutlet weak var chartView1: LineChartView!
    @IBOutlet weak var chartView2: LineChartView!
    @IBOutlet weak var chartView3: LineChartView!
    
    @IBOutlet weak var cpuTempTextField: NSTextField!
    @IBOutlet weak var gpuTempTextField: NSTextField!
    
    
    func valueInBounds<T : Comparable>(_ value: T, _ low: T, _ high: T) -> Bool {
        if value >= low && value <= high {
            return true
        }
        return false
    }
    
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        viewCPUtempFunction()
        viewGPUtempFunction()
        viewBodyFansSpeedFunction()
        
        chartView1.chartDescription?.position = .init(x: chartView1.bounds.width-45, y: 70)
        chartView2.chartDescription?.position = .init(x: chartView2.bounds.width-45, y: 70)
        chartView3.chartDescription?.position = .init(x: chartView3.bounds.width-45, y: 70)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.title = "Fuzzy Logic"
    }
    
    func dialogOKCancel(message: String, informativeText: String, alertStyle: NSAlert.Style = .critical) {
        let alert: NSAlert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.alertStyle = alertStyle
        alert.addButton(withTitle: "Ok")
        alert.runModal()
    }
    
    @IBAction func calculateButtonWasTapped(_ sender: NSButton) {
        guard let cpuTemp = Double(cpuTempTextField.cell?.title ?? ""), let gpuTemp = Double(gpuTempTextField.cell?.title ?? "")  else {
            dialogOKCancel(message: "Input error!", informativeText: "")
            return
        }
        
        let (cpuLow, cpuMid, cpuHigh) = cpuMembershipFunction(tCPU: cpuTemp)
        let (gpuLow, gpuMid, gpuHigh) = gpuMembershipFunction(tGPU: gpuTemp)
        
        //rules
        let cpuLowOrGpuLowRuleValue = max(cpuLow, gpuLow)
        let cpuMidAndGpuMidRuleValue = min(cpuMid, gpuMid)
        let cpuHighAndGpuHighRuleValue = min(cpuHigh, gpuHigh)
        
        //low or low -> low rule
        let data = LineChartData()
        let (lowChartPoints, midChartPoints, highChartPoints) = createChartDataPoints(inInterval: 0...2000, membershipFunction: bodyFansSpeedMembershipFunction(speedFans: ))
        
        data.addDataSets([
            createDataSet(name: "Low", points: lowChartPoints.map({ (item) -> ChartDataEntry in
                item.y *= cpuLowOrGpuLowRuleValue
                return item
            }), color: .blue),
            createDataSet(name: "Mid", points: midChartPoints.map({ (item) -> ChartDataEntry in
                item.y *= cpuMidAndGpuMidRuleValue
                return item
            }), color: .green),
            createDataSet(name: "High", points: highChartPoints.map({ (item) -> ChartDataEntry in
                item.y *= cpuHighAndGpuHighRuleValue
                return item
            }), color: .red)
            ])
        
        showChart(chartIndex: 2, name: "Body fans speed multiply", data: data, origin: .zero)
        
        //show merge chart (max combination)
        
        var resultEntries: [ChartDataEntry] = []
        var resultEntriesSumCombination: [ChartDataEntry] = []
        
        for i in 0..<data.dataSets[0].entryCount {
            let point1 = data.dataSets[0].entryForIndex(i)
            let point2 = data.dataSets[1].entryForIndex(i)
            let point3 = data.dataSets[2].entryForIndex(i)
            let points = [point1!, point2!, point3!]
            
            resultEntries.append(points.max(by: { (entry1, entry2) -> Bool in
                return entry1.y < entry2.y
            })!)
            
            resultEntriesSumCombination.append(ChartDataEntry(x: point1!.x, y: points.reduce(0, { (initial, nextPoint) -> Double in
                initial + nextPoint.y
            })))
            
        }
    
        showChart(chartIndex: 0, name: "Max combination", data: LineChartData(dataSet: createDataSet(name: "results", points: resultEntries, color: .darkGray)), origin: .zero)
        
        showChart(chartIndex: 1, name: "Sum combination", data: LineChartData(dataSet: createDataSet(name: "results", points: resultEntriesSumCombination, color: .blue)), origin: .zero)
        
        //calculate scalar
        let sumOfXMultY = resultEntries.reduce(0.0) { (previousValue, point) -> Double in
            return previousValue + point.x * point.y
        }
        
        let sumY = resultEntries.reduce(0.0) { (previousValue, point) -> Double in
            return previousValue + point.y
        }
        
        let mf = sumOfXMultY / sumY
        chartView1.data?.addDataSet(createDataSet(name: "results", points: [ChartDataEntry(x: mf, y: 0)], color: .red))
        chartView1.data = chartView1.data
        
        let maxNu = resultEntries.max { (e1, e2) -> Bool in
            return e1.y < e2.y
        }
        
        dialogOKCancel(message: "Result", informativeText: "(center of heavy) Speed fan must be \(mf)")
        dialogOKCancel(message: "Result", informativeText: "(max) Speed fan must be \(maxNu?.x)")
        
    }
    
    func viewCPUtempFunction() {
        let data = LineChartData()
        let (lowChartPoints, midChartPoints, highChartPoints) = createChartDataPoints(inInterval: 0...100, membershipFunction: cpuMembershipFunction(tCPU:))

        data.addDataSets([
            createDataSet(name: "Low", points: lowChartPoints, color: .blue),
            createDataSet(name: "Mid", points: midChartPoints, color: .green),
            createDataSet(name: "High", points: highChartPoints, color: .red)
            ])
        
        showChart(chartIndex: 0, name: "CPU temp", data: data, origin: .zero)
    }
    
    func viewGPUtempFunction() {
        let data = LineChartData()
        let (lowChartPoints, midChartPoints, highChartPoints) = createChartDataPoints(inInterval: 0...100, membershipFunction: gpuMembershipFunction(tGPU:))
        
        data.addDataSets([
            createDataSet(name: "Low", points: lowChartPoints, color: .blue),
            createDataSet(name: "Mid", points: midChartPoints, color: .green),
            createDataSet(name: "High", points: highChartPoints, color: .red)
            ])
        
        showChart(chartIndex: 1, name: "GPU temp", data: data, origin: .zero)
    }
    
    func viewBodyFansSpeedFunction() {
        let data = LineChartData()
        let (lowChartPoints, midChartPoints, highChartPoints) = createChartDataPoints(inInterval: 0...2000, membershipFunction: bodyFansSpeedMembershipFunction(speedFans: ))
        
        data.addDataSets([
            createDataSet(name: "Low", points: lowChartPoints, color: .blue),
            createDataSet(name: "Mid", points: midChartPoints, color: .green),
            createDataSet(name: "High", points: highChartPoints, color: .red)
            ])
        
        showChart(chartIndex: 2, name: "Body fans speed", data: data, origin: .zero)
    }
    
    func showChart(chartIndex: Int, name: String, data: ChartData, origin: NSPoint) {
        let chartView = [chartView1, chartView2, chartView3][chartIndex]!
        
        chartView.data = data

        chartView.setBoundsOrigin(origin)
        chartView.gridBackgroundColor = NSUIColor.white
        chartView.chartDescription?.text = name
    }
    
    
}

//MARK: - tCPU membership function
extension ViewController {
    
    //tCPU = 0...100
    func cpuMembershipFunction(tCPU: Double) -> (low: Double, mid: Double, high: Double) {
        func low(x: Double) -> Double {
            if valueInBounds(x, 0, 25) {
                return 1.0
            } else if valueInBounds(x, 25, 50) {
                return lineThroughtPoints(x: x, x1: 25, y1: 1, x2: 50, y2: 0)
            }
            return 0.0
        }
        
        func mid(x: Double) -> Double {
            if valueInBounds(x, 25, 50) {
                return lineThroughtPoints(x: x, x1: 25, y1: 0, x2: 50, y2: 1)
            } else if valueInBounds(x, 50, 75) {
                return lineThroughtPoints(x: x, x1: 50, y1: 1, x2: 75, y2: 0)
            }
            return 0.0
        }
        
        func high(x: Double) -> Double {
            if valueInBounds(x, 50, 75) {
                return 0.04*x - 2
            } else if valueInBounds(x, 75, 100) {
                return 1
            }
            return 0.0
        }
        
        return (low(x: tCPU), mid(x: tCPU), high(x: tCPU))
    }
    
    //tCPU = 0...100
    func gpuMembershipFunction(tGPU: Double) -> (low: Double, mid: Double, high: Double) {
        func low(x: Double) -> Double {
            if valueInBounds(x, 0, 30) {
                return 1.0
            } else if valueInBounds(x, 30, 60) {
                return lineThroughtPoints(x: x, x1: 30, y1: 1, x2: 60, y2: 0)
            }
            return 0.0
        }
        
        func mid(x: Double) -> Double {
            if valueInBounds(x, 30, 60) {
                return lineThroughtPoints(x: x, x1: 30, y1: 0, x2: 60, y2: 1)
            } else if valueInBounds(x, 60, 85) {
                return lineThroughtPoints(x: x, x1: 60, y1: 1, x2: 85, y2: 0)
            }
            return 0.0
        }
        
        func high(x: Double) -> Double {
            if valueInBounds(x, 60, 85) {
                return lineThroughtPoints(x: x, x1: 60, y1: 0, x2: 85, y2: 1)
            } else if valueInBounds(x, 85, 110) {
                return 1
            }
            return 0.0
        }
        
        return (low(x: tGPU), mid(x: tGPU), high(x: tGPU))
    }
    
    //tCPU = 0...100
    func bodyFansSpeedMembershipFunction(speedFans: Double) -> (low: Double, mid: Double, high: Double) {
        func low(x: Double) -> Double {
            if valueInBounds(x, 0, 700) {
                return 1.0
            } else if valueInBounds(x, 700, 1000) {
                return lineThroughtPoints(x: x, x1: 700, y1: 1, x2: 1000, y2: 0)
            }
            return 0.0
        }
        
        func mid(x: Double) -> Double {
            if valueInBounds(x, 700, 1000) {
                return lineThroughtPoints(x: x, x1: 700, y1: 0, x2: 1000, y2: 1)
            } else if valueInBounds(x, 700, 1300) {
                return lineThroughtPoints(x: x, x1: 1000, y1: 1, x2: 1300, y2: 0)
            }
            return 0.0
        }
        
        func high(x: Double) -> Double {
            if valueInBounds(x, 1000, 1300) {
                return lineThroughtPoints(x: x, x1: 1000, y1: 0, x2: 1300, y2: 1)
            } else if valueInBounds(x, 1300, 2000) {
                return 1
            }
            return 0.0
        }
        
        return (low(x: speedFans), mid(x: speedFans), high(x: speedFans))
    }
    
    func lineThroughtPoints(x: Double, x1: Double, y1: Double, x2: Double, y2: Double) -> Double {
        let k = (y1 - y2) / (x1 - x2)
        let b = y2 - k*x2
        return k*x + b
    }
}


//MARK: - Functions for datasets
extension ViewController {
    func createChartDataPoints(from: Int, to: Int, generate: Function) -> [ChartDataEntry] {
        //Generate points
        let yPoints = Array(from...to).map { x -> Double in
            return generate(Double(x))
        }
        
        var chartPoints: [ChartDataEntry] = []
        var yi = 0
        for x in from...to {
            chartPoints.append(ChartDataEntry(x: Double(x), y: yPoints[yi]))
            yi += 1
        }
        
        return chartPoints
    }
    
    func createChartDataPoints(inInterval: ClosedRange<Int>, membershipFunction: ((Double) -> ( low: Double, mid: Double, high: Double))) -> (low: [ChartDataEntry], mid: [ChartDataEntry], high: [ChartDataEntry]) {
        
        var lowPoints: [ChartDataEntry] = []
        var midPoints: [ChartDataEntry] = []
        var highPoints: [ChartDataEntry] = []
        
        for x in inInterval {
            let doubleX = Double(x)
            let (low, mid, high) = membershipFunction(doubleX)
            
            lowPoints.append(ChartDataEntry(x: doubleX, y: low))
            midPoints.append(ChartDataEntry(x: doubleX, y: mid))
            highPoints.append(ChartDataEntry(x: doubleX, y: high))
        }
     
        return (lowPoints, midPoints, highPoints)
    }
    
    func createDataSet(name: String, points: [ChartDataEntry], color: NSColor, circleRadius: CGFloat = 0) -> LineChartDataSet {
        let ds = LineChartDataSet(entries: points, label: name)
        ds.circleRadius = circleRadius
        ds.lineWidth = 4
        ds.colors = [color]
        return ds
    }
    
    func createDataSet(nameChart: String, from: Int, to: Int, generate: Function) -> ChartDataSet {
        let points = createChartDataPoints(from: from, to: to, generate: generate)
        let ds = createDataSet(name: nameChart, points: points, color: .blue)
        return ds
    }
}

extension LineChartData {
    func addDataSets(_ datas: [IChartDataSet]) {
        datas.forEach { (data) in
            addDataSet(data)
        }
    }
}

extension ChartDataSet {
    func setColor(_ color: NSColor) -> ChartDataSet {
        colors = [color]
        return self
    }
}

