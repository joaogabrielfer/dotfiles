import QtQuick
import Quickshell
import Quickshell.Widgets

ShellRoot {
    FloatingWindow {
        width: 320
		title: "powermenu"
        height: 420
		visible: true
        color: "transparent"

		Keys.onPressed: (event) => {
			if (event.key === Qt.Key_Escape) {
				Qt.quit();
			}

			if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier)) {
				Qt.quit();
			}
		}


        Rectangle {
            anchors.fill: parent
            color: "#181825"        // Mantle
            border.color: "#fab387" // Peach
            border.width: 0.5
            radius: 15

            Column {
                anchors.centerIn: parent
                spacing: 15

                Text {
                    text: "SISTEMA"
                    color: "#fab387"
                    font.pixelSize: 14
                    font.letterSpacing: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                component PowerEntry: Rectangle {
                    property string txt: ""
                    property string cmd: ""
                    width: 240
                    height: 55
                    color: "#313244"
                    radius: 10

                    Text {
                        text: parent.txt
                        anchors.centerIn: parent
                        color: "#cdd6f4"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = "#45475a"
                        onExited: parent.color = "#313244"
                        onClicked: {
                            Quickshell.execDetached(parent.cmd)
							Qt.quit()
                        }
                    }
                }

                PowerEntry { txt: "󰐥  DESLIGAR";   cmd: "poweroff" }
                PowerEntry { txt: "󰜉  REINICIAR"; cmd: "reboot" }
                // PowerEntry { txt: "󰒄  HIBERNAR";  cmd: "systemctl hibernate" }
                PowerEntry { txt: "󰷛  BLOQUEAR";  cmd: "hyprlock" }
            }
        }
    }
}
