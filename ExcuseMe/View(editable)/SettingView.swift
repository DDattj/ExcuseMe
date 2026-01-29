//
//  SettingView.swift
//  ExcuseMe
//
//  Created by 이시안 on 1/28/26.
//

import SwiftUI

struct SettingView: View {
    // 앱을 껐다 켜도 이 변수들은 UserDefaults에 자동 저장됨
    @AppStorage("isBGMOn") private var isBGMOn: Bool = true
    @AppStorage("isSFXOn") private var isSFXOn: Bool = true
    @AppStorage("isHapticOn") private var isHapticOn: Bool = true
    @AppStorage("userName") private var userName: String = "김출근" // 기본 닉네임
    
    // 초기화 경고창 띄우기용
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationStack {
            VStack (alignment: .leading, content: 0) {
                
                List{
                    // 사용자 정보 영역
                    Section {
                        NavigationLink {
                            // 닉네임 수정 화면으로 이동
                            ProfileEditView(name: $userName)
                        } label: {
                            HStack(spacing: 12) {
                                // 프로필 이미지 (임시로 시스템 아이콘 사용)
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(userName)
                                        .font(.headline)
                                    Text("UX/UI 디자이너 지망생") // 나중에 이것도 변수로 만들 수 있음
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("내 정보")
                    }
                    
                    // 게임 환경 설정 영역
                    Section {
                        Toggle(isOn: $isBGMOn) {
                            Label("배경 음악", systemImage: "music.note")
                        }
                        // 스위치 켰을 때 색상
                        .tint(.blue)
                        
                        Toggle(isOn: $isSFXOn) {
                            Label("효과음", systemImage: "speaker.wave.2.fill")
                        }
                        .tint(.blue)
                        
                        Toggle(isOn: $isHapticOn) {
                            Label("진동", systemImage: "iphone.gen3")
                        }
                        .tint(.blue)
                    } header: {
                        Text("환경 설정")
                    }
                    
                    // 앱 설명 영역
                    Section {
                        HStack {
                            Text("현재 버전")
                            Spacer()
                            Text("v1.0.0")
                                .foregroundColor(.secondary)
                        }
                        // 개발자 소개 링크 연결하고 싶으면 하고
                        Link(destination: URL(string: "https://www.google.com")!) {
                            HStack {
                                Text("개발자 포트폴리오")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .foregroundColor(.primary) // 링크 파란색 제거
                    } header: {
                        Text("앱 정보")
                    }
                    
                    // 초기화 버튼 영역
                    Section {
                        Button {
                            showResetAlert = true
                        } label: {
                            Text("게임 데이터 초기화")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.red)
                        }
                    } footer: {
                        Text("지금까지 깬 레벨과 획득한 코인이 모두 삭제됩니다.")
                    }
                }
            }
            .navigationTitle("설정")
            // 초기화 경고창
            .alert("정말 초기화하시겠습니까?", isPresented: $showResetAlert) {
                Button("취소", role: .cancel) { }
                Button("초기화", role: .destructive) {
                    GameData.shared.resetAllData()
                }
            } message: {
                Text("이 동작은 되돌릴 수 없습니다.")
            }
        }
    }
}

//간단한 닉네임 수정 화면
struct ProfileEditView: View {
    // SettingsView의 값을 직접 수정하도록 연결
    @Binding var name: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("닉네임") {
                TextField("이름을 입력하세요", text: $name)
                    .autocorrectionDisabled() // 자동수정 끄기
            }
        }
        .navigationTitle("프로필 수정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingView()
}
