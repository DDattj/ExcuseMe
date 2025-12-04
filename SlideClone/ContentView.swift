//
//  ContentView.swift
//  SlideClone
//
//  Created by 이시안 on 9/25/25.
//

import SwiftUI

struct Car {
    var row: Int
    var col: Int
    var length: Int
    var horizontal: Bool
    var color: Color
    var isGoal: Bool
}

struct ContentView: View {
    let rows = 6 //세로 칸
    let cols = 6 //가로 칸
    let spacing: CGFloat = 3 //칸 사이 간격

    @State private var cars: [Car] = []
    @State private var activeIndex: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var startRow: Int = 0
    @State private var startCol: Int = 0
    @State private var dragAxis: Axis? = nil

    private func generateRandomBoard(rows: Int, cols: Int) -> [Car] {
        var grid = Array(repeating: Array(repeating: false, count: cols), count: rows)
        var result: [Car] = []

        func canPlace(row: Int, col: Int, length: Int, horizontal: Bool) -> Bool {
            if horizontal {
                if col + length > cols { return false }
                for c in col..<(col+length) { if grid[row][c] { return false } }
            } else {
                if row + length > rows { return false }
                for r in row..<(row+length) { if grid[r][col] { return false } }
            }
            return true
        }

        func place(row: Int, col: Int, length: Int, horizontal: Bool) {
            if horizontal {
                for c in col..<(col+length) { grid[row][c] = true }
            } else {
                for r in row..<(row+length) { grid[r][col] = true }
            }
        }

        let goalRow = rows / 2
        let goalCar = Car(row: goalRow, col: 0, length: 2, horizontal: true, color: .red, isGoal: true)
        place(row: goalCar.row, col: goalCar.col, length: goalCar.length, horizontal: goalCar.horizontal)
        result.append(goalCar)

        // 랜덤한 장애물 생성 공간
        let obstacleCount = max(6, (rows * cols) / 8)
        for _ in 0..<obstacleCount {
            let length = Bool.random() ? 2 : 3
            let horizontal = Bool.random()
            if horizontal {
                let r = Int.random(in: 0..<rows)
                let c = Int.random(in: 0..<(cols - length + 1))
                if canPlace(row: r, col: c, length: length, horizontal: true) {
                    place(row: r, col: c, length: length, horizontal: true)
                    result.append(Car(row: r, col: c, length: length, horizontal: true, color: .blue, isGoal: false))
                }
            } else {
                let r = Int.random(in: 0..<(rows - length + 1))
                let c = Int.random(in: 0..<cols)
                if canPlace(row: r, col: c, length: length, horizontal: false) {
                    place(row: r, col: c, length: length, horizontal: false)
                    result.append(Car(row: r, col: c, length: length, horizontal: false, color: .green, isGoal: false))
                }
            }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 30) {
            //다시시작 버튼
            HStack {
                Button("Try Again!") {
                    let generated = generateRandomBoard(rows: rows, cols: cols)
                    cars = generated
                    //다시 시작할때 조건
                    activeIndex = nil
                    dragAxis = nil
                    dragOffset = .zero
                    startRow = cars.first?.row ?? 0
                    startCol = cars.first?.col ?? 0
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }

            GeometryReader { geo in

                let side = min(geo.size.width, geo.size.height) - 8
                let cell = (side - spacing * CGFloat(cols - 1)) / CGFloat(cols)

                let contentWidth  = cell * CGFloat(cols) + spacing * CGFloat(cols - 1)
                let contentHeight = cell * CGFloat(rows) + spacing * CGFloat(rows - 1)

                let gridOriginX = (side - contentWidth)  / 2
                let gridOriginY = (side - contentHeight) / 2

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: side, height: side)

                    VStack(spacing: spacing) {
                        ForEach(0..<rows, id: \.self) { _ in
                            HStack(spacing: spacing) {
                                ForEach(0..<cols, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.purple.opacity(0.18))
                                        .frame(width: cell, height: cell)
                                }
                            }
                        }
                    }
                    .frame(width: side, height: side)

                    ForEach(cars.indices, id: \.self) { i in
                        carView(for: cars[i], index: i, cell: cell, origin: CGSize(width: gridOriginX, height: gridOriginY))
                    }
                }
                .frame(width: side, height: side)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .padding()
        .onAppear {
            if cars.isEmpty {
                let generated = generateRandomBoard(rows: rows, cols: cols)
                cars = generated
                startRow = cars.first?.row ?? 0
                startCol = cars.first?.col ?? 0
            }
        }
    }

    func carView(for car: Car, index: Int, cell: CGFloat, origin: CGSize) -> some View {

        let width  = car.horizontal
            ? cell * CGFloat(car.length) + spacing * CGFloat(car.length - 1)
            : cell
        let height = car.horizontal
            ? cell
            : cell * CGFloat(car.length) + spacing * CGFloat(car.length - 1)

        //차 방향이나 기준점 바꾸고 싶을때 손대는 틀
        let offsetX = origin.width  + CGFloat(car.col) * (cell + spacing)
        let offsetY = origin.height + CGFloat(car.row) * (cell + spacing)

        return RoundedRectangle(cornerRadius: 16)
            .fill(car.color)
            .frame(width: width, height: height)
            .shadow(radius: 2)
            .overlay {
                if car.isGoal { Text("내 캐릭터").font(.system(size: 20)) }
            }
            .offset(x: offsetX + (activeIndex == index ? dragOffset.width : 0),
                    y: offsetY + (activeIndex == index ? dragOffset.height : 0))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if activeIndex == nil { activeIndex = index }
                        guard activeIndex == index else { return }
                        if dragAxis == nil {
                            let dx = abs(value.translation.width)
                            let dy = abs(value.translation.height)
                            dragAxis = dx >= dy ? .horizontal : .vertical
                            startRow = cars[index].row
                            startCol = cars[index].col
                        }

                        let step = cell + spacing
                        switch dragAxis {
                        case .horizontal:
                            var dx = value.translation.width
                            let movedColsFloat = dx / step
                            let tentativeCol = CGFloat(startCol) + movedColsFloat
                            let minCol = 0
                            let maxCol = cols - car.length
                            let clampedCol = min(max(tentativeCol, CGFloat(minCol)), CGFloat(maxCol))
                            dx = (clampedCol - CGFloat(startCol)) * step
                            dragOffset = CGSize(width: dx, height: 0)
                        case .vertical:
                            var dy = value.translation.height
                            let movedRowsFloat = dy / step
                            let tentativeRow = CGFloat(startRow) + movedRowsFloat
                            let minRow = 0
                            let maxRow = rows - car.length
                            let clampedRow = min(max(tentativeRow, CGFloat(minRow)), CGFloat(maxRow))
                            dy = (clampedRow - CGFloat(startRow)) * step
                            dragOffset = CGSize(width: 0, height: dy)
                        case .none:
                            break
                        }
                    }
                    .onEnded { _ in
                        guard activeIndex == index else { return }
                        let step = cell + spacing
                        if dragAxis == .horizontal {
                            let movedCols = (dragOffset.width / step).rounded()
                            let newCol = min(max(startCol + Int(movedCols), 0), cols - car.length)
                            cars[index].col = newCol
                        } else if dragAxis == .vertical {
                            let movedRows = (dragOffset.height / step).rounded()
                            let newRow = min(max(startRow + Int(movedRows), 0), rows - car.length)
                            cars[index].row = newRow
                        }
                        startRow = cars[index].row
                        startCol = cars[index].col
                        dragOffset = .zero
                        dragAxis = nil
                        activeIndex = nil
                    }
            )
    }
}

#Preview { ContentView() }
