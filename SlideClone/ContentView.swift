//
//  ContentView.swift
//  SlideClone
//
//  Created by 이시안 on 9/25/25.

//게임 화면으로 쓰일 UI 파일
// 색, 폰트, 레이아웃, 애니메이션: 전부 ContentView에서 수정.
import SwiftUI
// UI 전용 색 설정
extension Car {
    var color: Color {
        if isGoal {
            return .red
        } else {
            return horizontal ? .blue : .green
        }
    }
}

struct ContentView: View {
    let rows = 6 //세로 칸
    let cols = 6 //가로 칸
    let spacing: CGFloat = 3 //칸 사이 간격

    @StateObject private var vm: GameViewModel

    init(difficulty: Int = 1) {
        _vm = StateObject(
            wrappedValue: GameViewModel(rows: 6, cols: 6, goalExitSide: .right, difficulty: difficulty)
        )
    }

    @State private var activeIndex: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var startRow: Int = 0
    @State private var startCol: Int = 0
    @State private var dragAxis: Axis? = nil

    @State private var isDragging: Bool = false
    @State private var shakePhase: CGFloat = 0
    @State private var lastAllowedDelta: Int = 0

    // MARK: - 충돌 계산 (UI 쪽에서 사용하는 그리드)

    private func buildOccupancyGrid(excluding index: Int?) -> [[Bool]] {
        var grid = Array(repeating: Array(repeating: false, count: cols), count: rows)
        for (i, car) in vm.cars.enumerated() {
            if let index = index, i == index { continue }
            if car.horizontal {
                for c in car.col..<(car.col + car.length) { grid[car.row][c] = true }
            } else {
                for r in car.row..<(car.row + car.length) { grid[r][car.col] = true }
            }
        }
        return grid
    }

    private func allowedDelta(
        for car: Car,
        index: Int,
        axis: Axis,
        startRow: Int,
        startCol: Int,
        desiredDelta: Int
    ) -> Int {
        let grid = buildOccupancyGrid(excluding: index)

        switch axis {
        case .horizontal:
            if desiredDelta > 0 {
                // 오른쪽
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
                // 왼쪽
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
                // 아래
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
                // 위
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

    // MARK: - View

    var body: some View {
        VStack(spacing: 30) {
            //다시시작 버튼
            HStack {
                Button("Try Again!") {
                    vm.tryAgain()
                    activeIndex = nil
                    dragAxis = nil
                    dragOffset = .zero
                    startRow = vm.cars.first?.row ?? 0
                    startCol = vm.cars.first?.col ?? 0
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
                        switch vm.goalExitSide {
                        case .right:
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
                                    Capsule()
                                        .fill(Color.orange)
                                        .frame(width: spacing * 2, height: cell * 0.6)
                                )
                                .position(x: gridOriginX + contentWidth + spacing, y: y + cell/2)

                        case .left, .top, .bottom:
                            EmptyView()
                        }
                    }

                    ForEach(vm.cars.indices, id: \.self) { i in
                        carView(
                            for: vm.cars[i],
                            index: i,
                            cell: cell,
                            origin: CGSize(width: gridOriginX, height: gridOriginY)
                        )
                    }
                }
                .frame(width: side, height: side)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .padding()
        .alert("휴! 탈출이다", isPresented: $vm.hasWon) {
            Button("이동") {
                vm.tryAgain()
                activeIndex = nil
                dragAxis = nil
                dragOffset = .zero
                startRow = vm.cars.first?.row ?? 0
                startCol = vm.cars.first?.col ?? 0
            }
            Button("종료하기", role: .cancel) {}
        } message: {
            Text("잠시만요 횟수: \(vm.obstacleMoveCount)")
        }
        .onAppear {
            if vm.cars.isEmpty {
                vm.tryAgain()
                startRow = vm.cars.first?.row ?? 0
                startCol = vm.cars.first?.col ?? 0
            }
        }
    }

    // MARK: - Car View + 드래그

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
            .shadow(color: .black.opacity((activeIndex == index && isDragging) ? 0 : 0.2),
                    radius: 2, x: 0, y: 1)
            .background(
                Group {
                    if activeIndex == index && isDragging {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(car.color)
                            .padding(-spacing)
                    }
                }
            )
            .overlay {
                if car.isGoal { Text("내 캐릭터").font(.system(size: 20)) }
            }
            .offset(x: offsetX + (activeIndex == index ? dragOffset.width : 0),
                    y: offsetY + (activeIndex == index ? dragOffset.height : 0))
            .scaleEffect(activeIndex == index && isDragging ? 1.03 : 1.0, anchor: .center)
            .animation(.easeOut(duration: 0.12),
                       value: activeIndex == index && isDragging)
            .offset(
                x: {
                    if activeIndex == index {
                        if vm.cars[index].horizontal {
                            return (dragAxis == .vertical ? sin(shakePhase) * 2 : 0)
                        } else {
                            return 0
                        }
                    }
                    return 0
                }(),
                y: {
                    if activeIndex == index {
                        if !vm.cars[index].horizontal {
                            return (dragAxis == .horizontal ? sin(shakePhase) * 2 : 0)
                        } else {
                            return 0
                        }
                    }
                    return 0
                }()
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if activeIndex == nil { activeIndex = index }
                        guard activeIndex == index else { return }

                        if dragAxis == nil {
                            let dx = abs(value.translation.width)
                            let dy = abs(value.translation.height)
                            dragAxis = dx >= dy ? .horizontal : .vertical
                            // 차 방향으로 잠금
                            dragAxis = vm.cars[index].horizontal ? .horizontal : .vertical
                            startRow = vm.cars[index].row
                            startCol = vm.cars[index].col
                        }

                        let step = cell + spacing

                        switch dragAxis {
                        case .horizontal:
                            var dx = value.translation.width
                            let movedColsFloat = dx / step
                            let desiredCols = Int((movedColsFloat).rounded())

                            let minCol = 0
                            let maxCol = cols - car.length
                            let desiredNewCol = min(max(startCol + desiredCols, minCol), maxCol)
                            let desiredDelta = desiredNewCol - startCol

                            let allowed = allowedDelta(
                                for: vm.cars[index],
                                index: index,
                                axis: .horizontal,
                                startRow: startRow,
                                startCol: startCol,
                                desiredDelta: desiredDelta
                            )

                            lastAllowedDelta = allowed

                            if isDragging == false { isDragging = true }

                            if desiredDelta != 0 && allowed == 0 {
                                withAnimation(.easeOut(duration: 0.08)) { shakePhase = 6 }
                                withAnimation(.easeOut(duration: 0.16).delay(0.08)) { shakePhase = 0 }
                            }

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

                            let allowed = allowedDelta(
                                for: vm.cars[index],
                                index: index,
                                axis: .vertical,
                                startRow: startRow,
                                startCol: startCol,
                                desiredDelta: desiredDelta
                            )

                            lastAllowedDelta = allowed

                            if isDragging == false { isDragging = true }

                            if desiredDelta != 0 && allowed == 0 {
                                withAnimation(.easeOut(duration: 0.08)) { shakePhase = 6 }
                                withAnimation(.easeOut(duration: 0.16).delay(0.08)) { shakePhase = 0 }
                            }

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

                            let allowed = allowedDelta(
                                for: vm.cars[index],
                                index: index,
                                axis: .horizontal,
                                startRow: startRow,
                                startCol: startCol,
                                desiredDelta: desiredDelta
                            )

                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82, blendDuration: 0.1)) {
                                vm.cars[index].col = startCol + allowed
                            }
                            vm.applyMove(from: startRow, startCol: startCol, to: vm.cars[index].row, newCol: vm.cars[index].col, isGoal: vm.cars[index].isGoal)
                        } else if dragAxis == .vertical {
                            let movedRows = Int((dragOffset.height / step).rounded())
                            let minRow = 0
                            let maxRow = rows - car.length
                            let desiredNewRow = min(max(startRow + movedRows, minRow), maxRow)
                            let desiredDelta = desiredNewRow - startRow

                            let allowed = allowedDelta(
                                for: vm.cars[index],
                                index: index,
                                axis: .vertical,
                                startRow: startRow,
                                startCol: startCol,
                                desiredDelta: desiredDelta
                            )

                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82, blendDuration: 0.1)) {
                                vm.cars[index].row = startRow + allowed
                            }
                            vm.applyMove(from: startRow, startCol: startCol, to: vm.cars[index].row, newCol: vm.cars[index].col, isGoal: vm.cars[index].isGoal)
                        }

                        startRow = vm.cars[index].row
                        startCol = vm.cars[index].col
                        dragOffset = .zero
                        dragAxis = nil
                        activeIndex = nil
                        isDragging = false
                        shakePhase = 0
                    }
            )
            .zIndex(activeIndex == index && isDragging ? 10 : 0)
    }
}

#Preview {
    ContentView()
}
