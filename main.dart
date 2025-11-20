import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Doodles",
      home: SafeArea(
        child: DoodleBoard(),
      ),
    );
  }
}

class DoodleBoard extends StatefulWidget {
  @override
  _DoodleBoardState createState() => _DoodleBoardState();
}

class _DoodleBoardState extends State<DoodleBoard> {
  GlobalKey globalKey = GlobalKey();
  List<TouchPoints> pointsList = [];
  double opacity = 1.0;
  StrokeCap strokeType = StrokeCap.round;
  double strokeWidth = 3.0;
  Color selectedColor = Colors.black;

  Future<void> _pickStroke() async {
    //Shows AlertDialog
    return showDialog<void>(
      context: context,

      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose stroke'),
          //Creates four buttons to pick stroke value.
          actions: <Widget>[
            //Resetting to default stroke value
            TextButton(
              child: Icon(
                Icons.brush,
                size: 12,
              ),
              onPressed: () {
                strokeWidth = 3.0;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Icon(
                Icons.brush,
                size: 24,
              ),
              onPressed: () {
                strokeWidth = 8.0;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Icon(
                Icons.brush,
                size: 40,
              ),
              onPressed: () {
                strokeWidth = 20.0;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Icon(
                Icons.brush,
                size: 60,
              ),
              onPressed: () {
                strokeWidth = 40.0;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> _pickOpacity() async {
    //Shows AlertDialog
    return showDialog<void>(
      context: context,

      barrierDismissible: false, // user must tap button!

      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose opacity'),
          //Creates four buttons to pick opacity value.
          actions: <Widget>[
            TextButton(
              child: Icon(
                Icons.opacity,
                size: 12,
              ),
              onPressed: () {
                //most transparent
                opacity = 0.1;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Icon(
                Icons.opacity,
                size: 24,
              ),
              onPressed: () {
                //most transparent
                opacity = 0.4;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Icon(
                Icons.opacity,
                size: 40,
              ),
              onPressed: () {
                opacity = 0.7;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Icon(
                Icons.opacity,
                size: 60,
              ),
              onPressed: () {
                //not transparent at all.
                opacity = 1.0;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> _saveDrawing() async {
    RenderRepaintBoundary boundary = globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? pngBytes = byteData?.buffer.asUint8List();

    //Request permissions if not already granted
    if (!(await Permission.storage.status.isGranted))
      await Permission.storage.request();

    final result = await ImageGallerySaver.saveImage(
        pngBytes!,
        quality: 60,
        name:
            "canvas_image" + DateTime.now().millisecondsSinceEpoch.toString());
    print(result);
  }
  Future<void> _eraseDrawing() async {
    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erase Drawing'),
          content: Text('Would you like to erase the drawing?'),
          actions: <Widget>[
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                setState(() {
                  pointsList.clear();
                });
                Navigator.of(context).pop();
                print('Confirmed');
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> fabOption() {
    return <Widget>[
      FloatingActionButton(
        child: Icon(Icons.save),
        tooltip: 'Save', // long press the button to show the tooltip
        onPressed: () {
          setState(() {
            _saveDrawing();
          });
        },
      ),
      FloatingActionButton(
        child: Icon(Icons.brush),
        tooltip: 'Stroke',
        onPressed: () {
          //min: 0, max: 40
          setState(() {
            _pickStroke();
          });
        },
      ),
      FloatingActionButton(
        child: Icon(Icons.opacity),
        tooltip: 'Opacity',
        onPressed: () {
          //min:0, max:1
          setState(() {
            _pickOpacity();
          });
        },
      ),
      FloatingActionButton(
          child: Icon(Icons.clear),
          tooltip: "Erase",
          onPressed: () {
            _eraseDrawing();
          }),
      FloatingActionButton(
        backgroundColor: Colors.white,
        child: colorMenuItem(Colors.red),
        tooltip: 'Color', onPressed: () {  },
        // onPressed: () {
        //   setState(() {
        //     selectedColor = Colors.red;
        //   });
        // },
      ),
      FloatingActionButton(
        backgroundColor: Colors.white,
        child: colorMenuItem(Colors.green),
        tooltip: 'Color', onPressed: () {  },
      ),
      FloatingActionButton(
        backgroundColor: Colors.white,
        child: colorMenuItem(Colors.pink),
        tooltip: 'Color', onPressed: () {  },
      ),
      FloatingActionButton(
        backgroundColor: Colors.white,
        child: colorMenuItem(Colors.blue),
        tooltip: 'Color', onPressed: () {  },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanStart: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            pointsList.add(
              TouchPoints(
                points: renderBox.globalToLocal(details.globalPosition),
                paint: Paint()
                  ..strokeCap = strokeType
                  ..isAntiAlias = true
                  ..color = selectedColor.withOpacity(opacity)
                  ..strokeWidth = strokeWidth,
              ),
            );
          });
        },
        onPanUpdate: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            pointsList.add(
              TouchPoints(
                points: renderBox.globalToLocal(details.globalPosition),
                paint: Paint()
                  ..strokeCap = strokeType
                  ..isAntiAlias = true
                  ..color = selectedColor.withOpacity(opacity)
                  ..strokeWidth = strokeWidth,
              ),
            );
          });
        },
        onPanEnd: (details) {
          setState(() {
            //adding a marker indicting contact stopped
            pointsList.add(
              TouchPoints(
                points: Offset.infinite,
                paint: Paint()
              ),
            );
          });
        },
        child: RepaintBoundary(
          key: globalKey,
          child: Stack(
            children: <Widget>[
              Center(
                child: Image.asset("images/summer.png"),
              ),
              CustomPaint(
                size: Size.infinite,
                painter: MyPainter(
                  pointsList: pointsList,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ExpandableFab(
        distance: 240,
        children: [
          FloatingActionButton(
            child: Icon(Icons.save),
            tooltip: 'Save', // long press the button to show the tooltip
            onPressed: () {
              setState(() {
                _saveDrawing();
              });
            },
          ),
          FloatingActionButton(
            child: Icon(Icons.brush),
            tooltip: 'Stroke',
            onPressed: () {
              //min: 0, max: 40
              setState(() {
                _pickStroke();
              });
            },
          ),
          FloatingActionButton(
            child: Icon(Icons.opacity),
            tooltip: 'Opacity',
            onPressed: () {
              //min:0, max:1
              setState(() {
                _pickOpacity();
              });
            },
          ),
          FloatingActionButton(
              child: Icon(Icons.clear),
              tooltip: "Erase",
              onPressed: () {
                _eraseDrawing();
              }),
          FloatingActionButton(
            //backgroundColor: Colors.white,
            child: colorMenuItem(Colors.red),
            tooltip: 'Color',
            onPressed: () {}, //required by FAB, but do nothing here,
                              //let colorMenuItem handle the tapping
          ),
          FloatingActionButton(
            //backgroundColor: Colors.white,
            child: colorMenuItem(Colors.green),
            tooltip: 'Color',
            onPressed: () {},
          ),
          FloatingActionButton(
            //backgroundColor: Colors.white,
            child: colorMenuItem(Colors.pink),
            tooltip: 'Color',
            onPressed: () {},
          ),
          FloatingActionButton(
            //backgroundColor: Colors.white,
            child: colorMenuItem(Colors.blue),
            tooltip: 'Color',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget colorMenuItem(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.only(bottom: 8.0),
          height: 36,
          width: 36,
          color: color,
        ),
      ),
    );
  }
}
@immutable
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    this.initialOpen,
    required this.distance,
    required this.children,
  });

  final bool? initialOpen;
  final double distance;
  final List<Widget> children;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}
class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 90.0 / (count - 1);
    for (var i = 0, angleInDegrees = 0.0;
    i < count;
    i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: _toggle,
            child: const Icon(Icons.menu),
          ),
        ),
      ),
    );
  }
}
@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  MyPainter({required this.pointsList});

  //Keep track of the points tapped on the screen
  List<TouchPoints> pointsList;
  List<Offset> offsetPoints = [];

  //This is where we can draw on canvas.
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i]. points != Offset.infinite  && pointsList[i + 1].points != Offset.infinite) {
        //Drawing line when two consecutive points are available
        canvas.drawLine(pointsList[i].points, pointsList[i + 1].points,
            pointsList[i].paint);
      } else if (pointsList[i].points != Offset.infinite && pointsList[i + 1].points == Offset.infinite) {
        offsetPoints.clear();
        offsetPoints.add(pointsList[i].points);

        //Draw points when two points are not next to each other
        canvas.drawPoints(
            ui.PointMode.points, offsetPoints, pointsList[i].paint);
      }
    }
  }

  //Called when CustomPainter is rebuilt.
  //Returning true because we want canvas to be rebuilt to reflect new changes.
  @override
  bool shouldRepaint(MyPainter oldDelegate) => true;
}

//Class to define a point touched at canvas
class TouchPoints {
  Paint paint;
  Offset points;
  TouchPoints({required this.points, required this.paint});
}
