//
//  ContentView.swift
//  SlideClone
//
//  Created by 이시안 on 9/25/25.
//

import SwiftUI

struct ContentView: View {
    //행 6, 열 6, 사이간격 3
    let rows = 6
    let cols = 6
    let spacing: CGFloat = 3
    
    var body: some View {
        //보드를 정사각형으로 잡는 컨테이너 만들기
        GeometryReader { geo in
            //side = 가로나 세로 중 아무거나 24의 여백을 만들고 가로도 동일하게 한다
            //min 붙이는건 더 짧은쪽을 기준으로 삼겠다는 소리
            //24는 여백을 얼만큼 줄건지 설정하는 숫자
                    let side =
            min(geo.size.width, geo.size.height) - 8
            //cell은 보드 한 변의 길이에서
            let cell = (side - spacing * CGFloat(cols-1)) / CGFloat(cols)
            
                    ZStack {
                        // 보드 배경
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: side, height: side)
                        
                        VStack(spacing: spacing) {
                            ForEach(0..<rows, id: \.self) { _ in
                                HStack(spacing: spacing) {
                                    ForEach(0..<cols, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.gray.opacity(0.18))
                                            .frame(width: cell, height: cell)
                                    }
                                }
                            }
                        }
                    }
            //사각형을 가운데에 넣기위한 코드
                    .position(x: geo.size.width/2, y: geo.size.height/2)
                }
                .padding()
            }
        }

        #Preview { ContentView() }
