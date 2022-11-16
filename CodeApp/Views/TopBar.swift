//
//  tabBar.swift
//  Code
//
//  Created by Ken Chung on 1/7/2021.
//

import SwiftUI

struct TopBar: View {

    @EnvironmentObject var App: MainApp
    @EnvironmentObject var toolBarManager: ToolbarManager

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Binding var isShowingDirectory: Bool
    @Binding var showingSettingsSheet: Bool
    @Binding var showSafari: Bool
    let runCode: () -> Void
    let openConsolePanel: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            if !isShowingDirectory && horizontalSizeClass == .compact {
                Button(action: {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isShowingDirectory.toggle()
                    }
                }) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 17))
                        .foregroundColor(Color.init("T1"))
                        .padding(5)
                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .hoverEffect(.highlight)
                        .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20)
                        .padding()
                }
            }
            EditorTabs()
            Spacer()

            ForEach(toolBarManager.items) { item in
                ToolbarItemView(item: item)
            }

            if App.branch != "" && App.activeEditor?.type == .file {
                Button(action: {
                    if let url = URL(string: App.currentURL()) {
                        App.compareWithPrevious(url: url.standardizedFileURL)
                    }
                }) {
                    Image(systemName: "arrow.2.squarepath").font(.system(size: 17)).foregroundColor(
                        Color.init("T1")
                    ).padding(5)
                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .hoverEffect(.highlight)
                        .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20)
                        .padding()
                }
            }

            if App.activeEditor?.type == .diff {
                Image(systemName: "arrow.up").font(.system(size: 17)).foregroundColor(
                    Color.init("T1")
                ).padding(5)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .hoverEffect(.highlight)
                    .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20).padding()
                    .onTapGesture {
                        App.monacoInstance.executeJavascript(command: "navi.previous()")
                    }
                Image(systemName: "arrow.down").font(.system(size: 17)).foregroundColor(
                    Color.init("T1")
                ).padding(5)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .hoverEffect(.highlight)
                    .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20).padding()
                    .onTapGesture { App.monacoInstance.executeJavascript(command: "navi.next()") }
            }

            if let ext = App.currentURL().lowercased().components(separatedBy: ".").last,
                ext == "md" || ext == "markdown"
            {
                Image(systemName: "newspaper").font(.system(size: 17)).foregroundColor(
                    Color.init("T1")
                ).padding(5)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .hoverEffect(.highlight)
                    .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20).padding()
                    .onTapGesture {
                        guard let url = URL(string: App.activeEditor?.url ?? ""),
                            let content = App.activeEditor?.content
                        else {
                            return
                        }
                        App.addMarkDownPreview(url: url, content: content)
                    }
            }

            if App.activeEditor?.type == .file || App.activeEditor?.type == .diff {
                Image(systemName: "doc.text.magnifyingglass").font(.system(size: 17))
                    .foregroundColor(Color.init("T1")).padding(5)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .hoverEffect(.highlight)
                    .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20).padding()
                    .onTapGesture {
                        App.monacoInstance.executeJavascript(command: "editor.focus()")
                        App.monacoInstance.executeJavascript(
                            command: "editor.getAction('actions.find').run()")
                    }
            }

            Menu {
                if App.activeEditor?.type == .diff {
                    Section {
                        Button(action: {
                            App.monacoInstance.applyOptions(options: "renderSideBySide: false")
                        }) {
                            Label(
                                NSLocalizedString("Toogle Inline View", comment: ""),
                                systemImage: "doc.text")
                        }
                    }
                }
                Section {

                    Button(action: { App.closeAllEditors() }) {
                        Label("Close All", systemImage: "xmark")
                    }
                    if !App.workSpaceStorage.remoteConnected {
                        Button(action: { self.showSafari.toggle() }) {
                            Label("Preview in Safari", systemImage: "safari")
                        }
                    }
                }
                Divider()
                Section {
                    Button(action: {
                        App.openEditor(urlString: "welcome.md{welcome}", type: .preview)
                    }) {
                        Label("Show Welcome Page", systemImage: "newspaper")
                    }

                    Button(action: {
                        openConsolePanel()
                    }) {
                        Label("Show Panel", systemImage: "chevron.left.slash.chevron.right")
                    }

                    if UIApplication.shared.supportsMultipleScenes {
                        Button(action: {
                            UIApplication.shared.requestSceneSessionActivation(
                                nil, userActivity: nil, options: nil, errorHandler: nil)
                        }) {
                            Label("actions.new_window", systemImage: "square.split.2x1")
                        }
                    }

                    Button(action: {
                        showingSettingsSheet.toggle()
                    }) {
                        Label("Settings", systemImage: "slider.horizontal.3")
                    }
                }
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 17, weight: .light))
                    .foregroundColor(Color.init("T1")).padding(5)
                    .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .hoverEffect(.highlight)
                    .padding()
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
                    .environmentObject(App)
            }

        }
    }
}

private struct ToolbarItemView: View {

    @SceneStorage("panel.visible") var showsPanel: Bool = DefaultUIState.PANEL_IS_VISIBLE
    @SceneStorage("panel.focusedId") var currentPanel: String = DefaultUIState.PANEL_FOCUSED_ID

    let item: ToolbarItem

    var body: some View {
        Button(action: {
            if item.shouldFocusPanelOnTap {
                showsPanel = true
                currentPanel = item.extenionID
            }

            item.onClick()
        }) {
            Image(systemName: item.icon)
                .font(.system(size: 17))
                .foregroundColor(Color.init("T1"))
                .padding(5)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .hoverEffect(.highlight)
                .frame(minWidth: 0, maxWidth: 20, minHeight: 0, maxHeight: 20)
                .padding()
        }
    }

}
