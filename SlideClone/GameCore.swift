//
//  GameCore.swift
//  SlideClone
//
//  Created by 이시안 on 12/5/25.
//이곳은 게임 로직 담기는 곳
//보드 생성 규칙, 이동 가능 규칙, 승리 조건 등 “룰”을 바꿀 때 Core를 수정.

// GameCore.swift
import Foundation
import SwiftUI

struct Car: Hashable {
    var row: Int
    var col: Int
    var length: Int
    var horizontal: Bool
    var isGoal: Bool
}

struct GameCore {
    enum ExitSide { case left, right, top, bottom }

    let rows: Int
    let cols: Int
    let goalExitSide: ExitSide

    // MARK: - Grid helpers

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

    private func allowedDeltaInState(
        for cars: [Car],
        index: Int,
        axis: Axis,
        startRow: Int,
        startCol: Int,
        desiredDelta: Int
    ) -> Int {
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

    // MARK: - Goal / 평가

    func isGoalState(_ cars: [Car]) -> Bool {
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

            let maxPos = allowedDeltaInState(for: cars, index: i, axis: axis,
                                             startRow: car.row, startCol: car.col,
                                             desiredDelta: 99)
            if maxPos > 0 {
                for step in 1...maxPos {
                    var next = cars
                    if axis == .horizontal { next[i].col += step }
                    else { next[i].row += step }
                    result.append(Neighbor(cars: next, movedGoal: car.isGoal))
                }
            }

            let maxNeg = allowedDeltaInState(for: cars, index: i, axis: axis,
                                             startRow: car.row, startCol: car.col,
                                             desiredDelta: -99)
            if maxNeg < 0 {
                for step in 1...(-maxNeg) {
                    var next = cars
                    if axis == .horizontal { next[i].col -= step }
                    else { next[i].row -= step }
                    result.append(Neighbor(cars: next, movedGoal: car.isGoal))
                }
            }
        }

        return result
    }

    private func serialize(_ cars: [Car]) -> String {
        cars.map { "\($0.row),\($0.col)" }.joined(separator: ";")
    }

    // 0-1 BFS: 장애물 움직임 최소
    private func minimalObstacleMovesRequired(for initial: [Car]) -> Int? {
        let startKey = serialize(initial)
        var dist: [String: Int] = [startKey: 0]
        var queue: [String] = [startKey]
        var head = 0
        var stateByKey: [String: [Car]] = [startKey: initial]

        while head < queue.count {
            let key = queue[head]; head += 1
            guard let state = stateByKey[key] else { continue }

            if isGoalState(state) { return dist[key] }

            let currentCost = dist[key] ?? 0
            for nb in neighbors(of: state) {
                let nKey = serialize(nb.cars)
                let add = nb.movedGoal ? 0 : 1
                let newCost = currentCost + add
                if let existing = dist[nKey], existing <= newCost { continue }

                dist[nKey] = newCost
                stateByKey[nKey] = nb.cars
                if add == 0 {
                    queue.insert(nKey, at: head)   // 0 cost → 앞
                } else {
                    queue.append(nKey)             // 1 cost → 뒤
                }
            }
        }

        return nil
    }

    // MARK: - 보드 생성

    func generatePlayableBoard() -> [Car] {
        var attempts = 0
        while attempts < 300 {
            let board = generateRandomBoard()

            if isTriviallySolvableWithoutObstacles(board) {
                attempts += 1
                continue
            }

            if let minObstacle = minimalObstacleMovesRequired(for: board),
               minObstacle >= 1 {
                return board
            }
            attempts += 1
        }
        return generateRandomBoard()
    }

    private func generateRandomBoard() -> [Car] {
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

        // 목표 차량
        let goalRow = rows / 2
        let goalCar = Car(row: goalRow, col: 0, length: 2, horizontal: true, isGoal: true)
        place(row: goalCar.row, col: goalCar.col, length: goalCar.length, horizontal: goalCar.horizontal)
        result.append(goalCar)

        // 장애물
        let obstacleCount = max(6, (rows * cols) / 8)
        for _ in 0..<obstacleCount {
            let length = Bool.random() ? 2 : 3
            let horizontal = Bool.random()

            if horizontal {
                let r = Int.random(in: 0..<rows)
                let c = Int.random(in: 0..<(cols - length + 1))
                if canPlace(row: r, col: c, length: length, horizontal: true) {
                    place(row: r, col: c, length: length, horizontal: true)
                    result.append(Car(row: r, col: c, length: length, horizontal: true, isGoal: false))
                }
            } else {
                let r = Int.random(in: 0..<(rows - length + 1))
                let c = Int.random(in: 0..<cols)
                if canPlace(row: r, col: c, length: length, horizontal: false) {
                    place(row: r, col: c, length: length, horizontal: false)
                    result.append(Car(row: r, col: c, length: length, horizontal: false, isGoal: false))
                }
            }
        }

        return result
    }
}
