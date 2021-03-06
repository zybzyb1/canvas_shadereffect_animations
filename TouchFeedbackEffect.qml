// The MIT License (MIT)
//
// Copyright (c) 2015 Woboq GmbH
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import QtQuick 2.2
ShaderEffect {
    id: shaderEffect
    width: 512; height: 128
    opacity: 0

    // Properties that will get bound to a uniform with the same name in the shader
    property color backgroundColor: "#10000000"
    property color spreadColor: "#20000000"
    property point normTouchPos
    property real widthToHeightRatio: height / width
    // Our animated uniform property
    property real spread: 0

    ParallelAnimation {
        id: touchStartAnimation
        OpacityAnimator {
            target: shaderEffect
            from: 0; to: 1
            duration: 50; easing.type: Easing.InQuad
        }
        UniformAnimator {
            uniform: "spread"; target: shaderEffect
            from: 0; to: 1
            duration: 1000; easing.type: Easing.InQuad
        }
    }

    ParallelAnimation {
        id: touchEndAnimation
        OpacityAnimator {
            target: shaderEffect
            from: 1; to: 0
            duration: 1000; easing.type: Easing.OutQuad
        }
        UniformAnimator {
            uniform: "spread"; target: shaderEffect
            from: spread; to: 1
            duration: 1000; easing.type: Easing.OutQuad
        }
    }

    fragmentShader: "
        varying mediump vec2 qt_TexCoord0;
        uniform lowp float qt_Opacity;
        uniform lowp vec4 backgroundColor;
        uniform lowp vec4 spreadColor;
        uniform mediump vec2 normTouchPos;
        uniform mediump float widthToHeightRatio;
        uniform mediump float spread;

        void main() {
            // Pin the touched position of the circle by moving the center as
            // the radius grows. Both left and right ends of the circle should
            // touch the item edges simultaneously.
            mediump float radius = (0.5 + abs(0.5 - normTouchPos.x)) * 1.0 * spread;
            mediump vec2 circleCenter =
                normTouchPos + (vec2(0.5) - normTouchPos) * radius * 2.0;

            // Calculate everything according to the x-axis assuming that
            // the overlay is horizontal or square. Keep the aspect for the
            // y-axis since we're dealing with 0..1 coordinates.
            mediump float circleX = (qt_TexCoord0.x - circleCenter.x);
            mediump float circleY = (qt_TexCoord0.y - circleCenter.y) * widthToHeightRatio;

            // Use step to apply the color only if x2*y2 < r2.
            lowp vec4 tapOverlay =
                spreadColor * step(circleX*circleX + circleY*circleY, radius*radius);
            gl_FragColor = (backgroundColor + tapOverlay) * qt_Opacity;
        }
    "

    function touchStart(x, y) {
        normTouchPos = Qt.point(x / width, y / height)
        touchEndAnimation.stop()
        touchStartAnimation.start()
    }
    function touchEnd() {
        touchStartAnimation.stop()
        touchEndAnimation.start()
    }

    // Allows it to work standalone
    MouseArea {
        anchors.fill: parent
        onPressed: touchStart(mouse.x, mouse.y)
        onReleased: touchEnd()
    }
}
