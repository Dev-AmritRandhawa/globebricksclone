import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:globebricks/lottie_animation/animation.dart';
import 'package:globebricks/my_flutter_app_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class PropertySearching extends StatefulWidget {
  final List<String> propertyFilter;

  const PropertySearching({super.key, required this.propertyFilter});

  @override
  State<PropertySearching> createState() => _PropertySearchingState();
}

class _PropertySearchingState extends State<PropertySearching>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool loaded = true;
  FirebaseFirestore server = FirebaseFirestore.instance;

  int currentPage = 0;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    server.terminate();
    if (_controller.isCompleted) {
      _controller.dispose();
    }
    super.dispose();
  }

  final firestore = FirebaseFirestore.instance;
  bool loading = true;
  PanelController pc = PanelController();

  @override
  Widget build(BuildContext context) {
    double maxHeight = MediaQuery.of(context).size.height;
    double minHeight = 0;

    WidgetsBinding.instance.addPostFrameCallback(
        (_) => Future.delayed(const Duration(milliseconds: 2000), () async {
              if (mounted) {
                setState(() {
                  loading = false;
                });
              }
            }));

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SlidingUpPanel(
          maxHeight: maxHeight,
          minHeight: minHeight,
          parallaxEnabled: true,
          parallaxOffset: .5,
          isDraggable: false,
          body: _body(),
          controller: pc,
          panelBuilder: (sc) => _panel(sc),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18.0), topRight: Radius.circular(18.0)),
        ));
  }

  Widget _body() {
    const GeoPoint tokyoStation = GeoPoint(35.681236, 139.767125);
    const GeoFirePoint center = GeoFirePoint(tokyoStation);
    const double radiusInKm = 50;
    const String field = 'geo';

    final CollectionReference<Map<String, dynamic>> collectionReference =
        FirebaseFirestore.instance.collection('locations');
    GeoPoint geopointFrom(Map<String, dynamic> data) =>
        (data['geo'] as Map<String, dynamic>)['geopoint'] as GeoPoint;

    final Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream =
        GeoCollectionReference<Map<String, dynamic>>(collectionReference)
            .subscribeWithin(
      center: center,
      radiusInKm: radiusInKm,
      field: field,
      geopointFrom: geopointFrom,
      // Specify queryBuilder parameter here.
      queryBuilder: (query) => query.where('isVisible', isEqualTo: true).where("propertyRent",isEqualTo: 15000),
    );

    return loading
        ? Center(
            child: SizedBox(
                height: MediaQuery.of(context).size.height / 4,
                width: MediaQuery.of(context).size.height / 4,
                child:
                    const LottieAnimate(assetName: "assets/searchingMap.json")))
        : StreamBuilder<List<DocumentSnapshot>>(
            stream: stream,
            builder: (BuildContext context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!.isEmpty) {
                  if (!pc.isPanelOpen) {
                    pc.open();
                  }
                }
                final List<DocumentSnapshot<Object?>>? docs = snapshot.data;
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: docs!.length,
                  itemBuilder: (_, index) {
                    final doc = docs[index];
                    List<dynamic> data = doc.get("images");

                    return GestureDetector(
                      onTap: () {},
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        child: Column(children: [
                          CarouselSlider.builder(
                            itemCount: data.length,
                            itemBuilder: (BuildContext context, int itemIndex,
                                    int pageViewIndex) =>
                                Image.network(
                              data[itemIndex],
                              errorBuilder: (context, error, stackTrace) {
                                return const Text("Network Error");
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  enabled: true,
                                  child: Flexible(
                                      child: Image.asset("assets/logo.png")),
                                );
                              },
                            ),
                            options: CarouselOptions(
                              initialPage: 0,
                              enlargeCenterPage: true,
                              enlargeFactor: 0.3,
                              scrollDirection: Axis.horizontal,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    doc.get(
                                      "propertyTitle",
                                    ),
                                    maxLines: 3,
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                20),
                                  ),
                                ),
                                const Icon(
                                  Icons.favorite_border,
                                  color: Colors.black54,
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [Text(doc.get("propertyStatus"))],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    doc.get(
                                      "propertyDescription",
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                    softWrap: true,
                                    style: TextStyle(
                                        color: Colors.black54,
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                30),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "Rs.",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    doc.get("propertyRent").toString(),
                                    style: TextStyle(
                                        fontFamily: "Nunito",
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                20),
                                  ),
                                  const Text(
                                    "/ Month",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    doc.get("area").toString(),
                                    style: TextStyle(
                                        fontFamily: "Nunito",
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                20),
                                  ),
                                  const Text(" Square Feet"),
                                ],
                              )
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                    backgroundColor: doc.get("isPremium")
                                        ? Colors.green
                                        : Colors.blueGrey,
                                    child: const Icon(
                                      Icons.account_circle_rounded,
                                      color: Colors.white,
                                    )),
                                const Text(" Posted by: "),
                                Text(
                                  doc.get(
                                    "postedBy",
                                  ),
                                  style: const TextStyle(
                                      fontFamily: "Nunito",
                                      fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: [
                                    const Text(" ("),
                                    Text(doc.get(
                                      "postedByType",
                                    )),
                                    const Text(")"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 50),
                            child: Row(
                              children: [
                                const Text(
                                  "Date: ",
                                  style: TextStyle(color: Colors.black54),
                                ),
                                Text(doc.get("uploadDate")),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const CircleAvatar(
                                  child: Icon(
                                    Icons.call,
                                    color: Colors.white,
                                  ),
                                ),
                                CupertinoButton(
                                    borderRadius: BorderRadius.circular(30),
                                    color: Colors.indigo,
                                    child: const Text(
                                      "View Number",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () {}),
                                const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Icon(
                                    MyFlutterApp.whatsapp,
                                    color: Colors.white,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                );
              } else {
                return Platform.isIOS
                    ? const Center(
                        child: CupertinoActivityIndicator(
                        color: Colors.black54,
                      ))
                    : const Center(
                        child: CircularProgressIndicator(
                        backgroundColor: Colors.black54,
                      ));
              }
            },
          );
  }

  _panel(ScrollController sc) {
    return Center(
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Unfortunately there's no property available at this location try to change location or increase the radius of your search,",
                style: TextStyle(fontSize: 20, fontFamily: "Nunito"),
              ),
            ),
            CupertinoButton(
                color: Colors.yellow,
                child: const Text(
                  "Change Location",
                  style: TextStyle(color: Colors.black54),
                ),
                onPressed: () {
                  Navigator.pop(context);
                }),
            const LottieAnimate(assetName: "assets/ob.json"),
          ],
        ),
      ),
    );
  }

  Future<void> dataExisting(
      Stream<List<DocumentSnapshot<Object?>>> stream) async {
    if (await stream.isEmpty) {
      pc.open();
    }
  }
}
