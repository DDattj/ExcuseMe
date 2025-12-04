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

    // Win condition configuration
    enum ExitSide { case left, right, top, bottom }
    let goalExitSide: ExitSide = .right
    @State private var hasWon: Bool = false
    @State private var moveCount: Int = 0
    @State private var obstacleMoveCount: Int = 0

    private func buildOccupancyGrid(excluding index: Int?) -> [[Bool]] {
        var grid = Array(repeating: Array(repeating: false, count: cols), count: rows)
        for (i, car) in cars.enumerated() {
            if let index = index, i == index { continue }
            if car.horizontal {
                for c in car.col..<(car.col + car.length) { grid[car.row][c] = true }
            } else {
                for r in car.row..<(car.row + car.length) { grid[r][car.col] = true }
            }
        }
        return grid
    }

    private func allowedDelta(for car: Car, index: Int, axis: Axis, startRow: Int, startCol: Int, desiredDelta: Int) -> Int {
        let grid = buildOccupancyGrid(excluding: index)
        switch axis {
        case .horizontal:
            if desiredDelta > 0 {
                // moving right
                var maxSteps = 0
                let startEdge = startCol + car.length - 1
                var nextCol = startEdge + 1
                while maxSteps < desiredDelta && nextCol < cols {
                    if grid[car.row][nextCol] { break }
                    maxSteps += 1
                    nextCol += 1
                }
                return maxSteps
            } else if desiredDelta < 0 {
                // moving left
                var maxSteps = 0
                var nextCol = startCol - 1
                while maxSteps < -desiredDelta && nextCol >= 0 {
                    if grid[car.row][nextCol] { break }
                    maxSteps += 1
                    nextCol -= 1
                }
                return -maxSteps
            } else {
                return 0
            }
        case .vertical:
            if desiredDelta > 0 {
                // moving down
                var maxSteps = 0
                let startEdge = startRow + car.length - 1
                var nextRow = startEdge + 1
                while maxSteps < desiredDelta && nextRow < rows {
                    if grid[nextRow][car.col] { break }
                    maxSteps += 1
                    nextRow += 1
                }
                return maxSteps
            } else if desiredDelta < 0 {
                // moving up
                var maxSteps = 0
                var nextRow = startRow - 1
                while maxSteps < -desiredDelta && nextRow >= 0 {
                    if grid[nextRow][car.col] { break }
                    maxSteps += 1
                    nextRow -= 1
                }
                return -maxSteps
            } else {
                return 0
            }
        }
    }

    // MARK: - Puzzle evaluation helpers

    private func buildGrid(for cars: [Car], excluding index: Int?) -> [[Bool]] {
        var grid = Array(repeating: Array(repeating: false, count: cols), count: rows)
        for (i, car) in cars.enumerated() {
            if let index = index, i == index { continue }
            if car.horizontal {
                for c in car.col..<(car.col + car.length) { grid[car.row][c] = true }
            } else {
                for r in car.row..<(car.row + car.length) { grid[r][car.col] = true }
            }
        }
        return grid
    }

    private func allowedDeltaInState(for cars: [Car], index: Int, axis: Axis, startRow: Int, startCol: Int, desiredDelta: Int) -> Int {
        let car = cars[index]
        let grid = buildGrid(for: cars, excluding: index)
        switch axis {
        case .horizontal:
            if desiredDelta > 0 {
                var maxSteps = 0
                let startEdge = startCol + car.length - 1
                var nextCol = startEdge + 1
                while maxSteps < desiredDelta && nextCol < cols {
                    if grid[car.row][nextCol] { break }
                    maxSteps += 1
                    nextCol += 1
                }
                return maxSteps
            } else if desiredDelta < 0 {
                var maxSteps = 0
                var nextCol = startCol - 1
                while maxSteps < -desiredDelta && nextCol >= 0 {
                    if grid[car.row][nextCol] { break }
                    maxSteps += 1
                    nextCol -= 1
                }
                return -maxSteps
            } else {
                return 0
            }
        case .vertical:
            if desiredDelta > 0 {
                var maxSteps = 0
                let startEdge = startRow + car.length - 1
                var nextRow = startEdge + 1
                while maxSteps < desiredDelta && nextRow < rows {
                    if grid[nextRow][car.col] { break }
                    maxSteps += 1
                    nextRow += 1
                }
                return maxSteps
            } else if desiredDelta < 0 {
                var maxSteps = 0
                var nextRow = startRow - 1
                while maxSteps < -desiredDelta && nextRow >= 0 {
                    if grid[nextRow][car.col] { break }
                    maxSteps += 1
                    nextRow -= 1
                }
                return -maxSteps
            } else {
                return 0
            }
        }
    }

    private func isGoalState(_ cars: [Car]) -> Bool {
        guard let goalIndex = cars.firstIndex(where: { $0.isGoal }) else { return false }
        let goal = cars[goalIndex]
        switch goalExitSide {
        case .right:
            return goal.horizontal && goal.row == rows / 2 && (goal.col + goal.length - 1) == cols - 1
        case .left:
            return goal.horizontal && goal.row == rows / 2 && goal.col == 0
        case .top:
            return !goal.horizontal && goal.col == cols / 2 && goal.row == 0
        case .bottom:
            return !goal.horizontal && goal.col == cols / 2 && (goal.row + goal.length - 1) == rows - 1
        }
    }

    private func isTriviallySolvableWithoutObstacles(_ cars: [Car]) -> Bool {
        guard let goalIndex = cars.firstIndex(where: { $0.isGoal }) else { return false }
        let goal = cars[goalIndex]
        switch goalExitSide {
        case .right:
            guard goal.horizontal && goal.row == rows / 2 else { return false }
            let grid = buildGrid(for: cars, excluding: goalIndex)
            let startC = goal.col + goal.length
            if startC > cols - 1 { return true }
            for c in startC..<cols {
                if grid[goal.row][c] { return false }
            }
            return true
        case .left:
            guard goal.horizontal && goal.row == rows / 2 else { return false }
            let grid = buildGrid(for: cars, excluding: goalIndex)
            let endC = goal.col - 1
            if endC < 0 { return true }
            for c in 0...endC {
                if grid[goal.row][c] { return false }
            }
            return true
        case .top:
            guard !goal.horizontal && goal.col == cols / 2 else { return false }
            let grid = buildGrid(for: cars, excluding: goalIndex)
            let endR = goal.row - 1
            if endR < 0 { return true }
            for r in 0...endR {
                if grid[r][goal.col] { return false }
            }
            return true
        case .bottom:
            guard !goal.horizontal && goal.col == cols / 2 else { return false }
            let grid = buildGrid(for: cars, excluding: goalIndex)
            let startR = goal.row + goal.length
            if startR > rows - 1 { return true }
            for r in startR..<rows {
                if grid[r][goal.col] { return false }
            }
            return true
        }
    }

    private struct Neighbor {
        let cars: [Car]
        let movedGoal: Bool
    }

    private func neighbors(of cars: [Car]) -> [Neighbor] {
        var result: [Neighbor] = []
        for i in cars.indices {
            let car = cars[i]
            let axis: Axis = car.horizontal ? .horizontal : .vertical
            let maxPos = allowedDeltaInState(for: cars, index: i, axis: axis, startRow: car.row, startCol: car.col, desiredDelta: 99)
            if maxPos > 0 {
                for step in 1...maxPos {
                    var next = cars
                    if axis == .horizontal {
                        next[i].col += step
                    } else {
                        next[i].row += step
                    }
                    result.append(Neighbor(cars: next, movedGoal: car.isGoal))
                }
            }
            let maxNeg = allowedDeltaInState(for: cars, index: i, axis: axis, startRow: car.row, startCol: car.col, desiredDelta: -99)
            if maxNeg < 0 {
                for step in 1...(-maxNeg) {
                    var next = cars
                    if axis == .horizontal {
                        next[i].col -= step
                    } else {
                        next[i].row -= step
                    }
                    result.append(Neighbor(cars: next, movedGoal: car.isGoal))
                }
            }
        }
        return result
    }

    private func serialize(_ cars: [Car]) -> String {
        cars.map { "\($0.row),\($0.col)" }.joined(separator: ";")
    }

    // 0-1 BFS to minimize obstacle moves (goal moves cost 0, obstacle moves cost 1)
    private func minimalObstacleMovesRequired(for initial: [Car]) -> Int? {
        let startKey = serialize(initial)
        var dist: [String: Int] = [startKey: 0]
        var queue: [String] = [startKey]
        var head = 0
        var stateByKey: [String: [Car]] = [startKey: initial]

        while head < queue.count {
            let key = queue[head]; head += 1
            guard let state = stateByKey[key] else { continue }
            if isGoalState(state) {
                return dist[key]
            }
            let currentCost = dist[key] ?? 0
            for nb in neighbors(of: state) {
                let nKey = serialize(nb.cars)
                let add = nb.movedGoal ? 0 : 1
                let newCost = currentCost + add
                if let existing = dist[nKey], existing <= newCost { continue }
                dist[nKey] = newCost
                stateByKey[nKey] = nb.cars
                if add == 0 {
                    queue.insert(nKey, at: head) // push-front for 0-cost edges
                } else {
                    queue.append(nKey)
                }
            }
        }
        return nil
    }

    //장애물 놓는 공간 설정
    private func generatePlayableBoard(rows: Int, cols: Int) -> [Car] {
        var attempts = 0
        while attempts < 300 {
            let board = generateRandomBoard(rows: rows, cols: cols)
            // 최소한의 움직임은 있어야함
            if isTriviallySolvableWithoutObstacles(board) {
                attempts += 1
                continue
            }
            // 움직이고서 나갈 수 있어야 함?
            if let minObstacle = minimalObstacleMovesRequired(for: board), minObstacle >= 1 {
                return board
            }
            attempts += 1
        }
        // Fallback
        return generateRandomBoard(rows: rows, cols: cols)
    }

    private func checkWinCondition() {
        guard let goalIndex = cars.firstIndex(where: { $0.isGoal }) else { return }
        let goal = cars[goalIndex]
        switch goalExitSide {
        case .right:
            // Goal car exits to the right when its tail touches last column (cols - 1)
            if goal.horizontal && goal.row == rows / 2 && (goal.col + goal.length - 1) == cols - 1 {
                hasWon = true
            }
        case .left:
            if goal.horizontal && goal.row == rows / 2 && goal.col == 0 {
                hasWon = true
            }
        case .top:
            if !goal.horizontal && goal.col == cols / 2 && goal.row == 0 {
                hasWon = true
            }
        case .bottom:
            if !goal.horizontal && goal.col == cols / 2 && (goal.row + goal.length - 1) == rows - 1 {
                hasWon = true
            }
        }
    }

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
                    let generated = generatePlayableBoard(rows: rows, cols: cols)
                    cars = generated
                    //다시 시작할때 조건
                    activeIndex = nil
                    dragAxis = nil
                    dragOffset = .zero
                    startRow = cars.first?.row ?? 0
                    startCol = cars.first?.col ?? 0
                    hasWon = false
                    moveCount = 0
                    obstacleMoveCount = 0
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

                    // Exit marker
                    Group {
                        switch goalExitSide {
                        case .right:
                            // draw a gap/marker on the middle-right edge
                            let cell = (side - spacing * CGFloat(cols - 1)) / CGFloat(cols)
                            let contentWidth  = cell * CGFloat(cols) + spacing * CGFloat(cols - 1)
                            let contentHeight = cell * CGFloat(rows) + spacing * CGFloat(rows - 1)
                            let gridOriginX = (side - contentWidth)  / 2
                            let gridOriginY = (side - contentHeight) / 2
                            let y = gridOriginY + CGFloat(rows / 2) * (cell + spacing)
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: spacing * 2, height: cell)
                                .overlay(
                                    Capsule().fill(Color.orange).frame(width: spacing * 2, height: cell * 0.6)
                                )
                                .position(x: gridOriginX + contentWidth + spacing, y: y + cell/2)
                        case .left, .top, .bottom:
                            EmptyView()
                        }
                    }

                    ForEach(cars.indices, id: \.self) { i in
                        carView(for: cars[i], index: i, cell: cell, origin: CGSize(width: gridOriginX, height: gridOriginY))
                    }
                }
                .frame(width: side, height: side)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .padding()
        .alert("휴! 탈출이다", isPresented: $hasWon) {
            Button("나가기") {
                let generated = generatePlayableBoard(rows: rows, cols: cols)
                cars = generated
                activeIndex = nil
                dragAxis = nil
                dragOffset = .zero
                startRow = cars.first?.row ?? 0
                startCol = cars.first?.col ?? 0
                hasWon = false
                moveCount = 0
                obstacleMoveCount = 0
            }
            Button("닫기", role: .cancel) {}
        } message: {
            Text("잠시만요 — 장애물 이동 횟수: \(obstacleMoveCount)")
        }
        .onAppear {
            if cars.isEmpty {
                let generated = generatePlayableBoard(rows: rows, cols: cols)
                cars = generated
                startRow = cars.first?.row ?? 0
                startCol = cars.first?.col ?? 0
                hasWon = false
                moveCount = 0
                obstacleMoveCount = 0
                checkWinCondition()
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
                            // lock axis to car orientation
                            if cars[index].horizontal {
                                dragAxis = .horizontal
                            } else {
                                dragAxis = .vertical
                            }
                            startRow = cars[index].row
                            startCol = cars[index].col
                        }

                        let step = cell + spacing
                        switch dragAxis {
                        case .horizontal:
                            var dx = value.translation.width
                            let movedColsFloat = dx / step
                            let desiredCols = Int((movedColsFloat).rounded())
                            // limit by board bounds first
                            let minCol = 0
                            let maxCol = cols - car.length
                            let desiredNewCol = min(max(startCol + desiredCols, minCol), maxCol)
                            let desiredDelta = desiredNewCol - startCol
                            // limit by collisions
                            let allowed = allowedDelta(for: cars[index], index: index, axis: .horizontal, startRow: startRow, startCol: startCol, desiredDelta: desiredDelta)
                            dx = CGFloat(allowed) * step
                            dragOffset = CGSize(width: dx, height: 0)
                        case .vertical:
                            var dy = value.translation.height
                            let movedRowsFloat = dy / step
                            let desiredRows = Int((movedRowsFloat).rounded())
                            let minRow = 0
                            let maxRow = rows - car.length
                            let desiredNewRow = min(max(startRow + desiredRows, minRow), maxRow)
                            let desiredDelta = desiredNewRow - startRow
                            let allowed = allowedDelta(for: cars[index], index: index, axis: .vertical, startRow: startRow, startCol: startCol, desiredDelta: desiredDelta)
                            dy = CGFloat(allowed) * step
                            dragOffset = CGSize(width: 0, height: dy)
                        case .none:
                            break
                        }
                    }
                    .onEnded { _ in
                        guard activeIndex == index else { return }
                        let step = cell + spacing
                        if dragAxis == .horizontal {
                            let movedCols = Int((dragOffset.width / step).rounded())
                            let minCol = 0
                            let maxCol = cols - car.length
                            let desiredNewCol = min(max(startCol + movedCols, minCol), maxCol)
                            let desiredDelta = desiredNewCol - startCol
                            let allowed = allowedDelta(for: cars[index], index: index, axis: .horizontal, startRow: startRow, startCol: startCol, desiredDelta: desiredDelta)
                            cars[index].col = startCol + allowed
                        } else if dragAxis == .vertical {
                            let movedRows = Int((dragOffset.height / step).rounded())
                            let minRow = 0
                            let maxRow = rows - car.length
                            let desiredNewRow = min(max(startRow + movedRows, minRow), maxRow)
                            let desiredDelta = desiredNewRow - startRow
                            let allowed = allowedDelta(for: cars[index], index: index, axis: .vertical, startRow: startRow, startCol: startCol, desiredDelta: desiredDelta)
                            cars[index].row = startRow + allowed
                        }
                        if startRow != cars[index].row || startCol != cars[index].col {
                            moveCount += 1
                            if cars[index].isGoal == false {
                                obstacleMoveCount += 1
                            }
                        }
                        checkWinCondition()
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

