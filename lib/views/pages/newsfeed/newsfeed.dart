import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:talawa/services/Queries.dart';
import 'package:talawa/services/preferences.dart';
import 'package:talawa/utils/apiFuctions.dart';
import 'package:talawa/views/pages/newsfeed/addPost.dart';
import 'package:talawa/views/pages/newsfeed/newsArticle.dart';
import 'package:talawa/utils/uidata.dart';
import 'package:talawa/utils/timer.dart';
import 'package:talawa/views/widgets/custom_appbar.dart';

class NewsFeed extends StatefulWidget {
  NewsFeed({Key key}) : super(key: key);

  @override
  _NewsFeedState createState() => _NewsFeedState();
}

class _NewsFeedState extends State<NewsFeed> {

  ScrollController scrollController = new ScrollController();
  bool isVisible = true;
  Preferences preferences = Preferences();
  ApiFunctions apiFunctions = ApiFunctions();
  List postList = [];
  String name;
  Timer timer = Timer();

  initState() {
    super.initState();
    getPosts();
    Provider.of<Preferences>(context, listen: false).getCurrentOrgId();
      scrollController.addListener(() {
        if (scrollController.position.userScrollDirection ==
            ScrollDirection.reverse) {
          if (isVisible)
            setState(() {
              isVisible = false;
            });
        }
        if (scrollController.position.userScrollDirection ==
            ScrollDirection.forward) {
          if (!isVisible)
            setState(() {
              isVisible = true;
            });
        }
    });
  }

  Future<void> getPosts() async {
    final String currentOrgID = await preferences.getCurrentOrgId();
    String query = Queries().getPostsById(currentOrgID);
    Map result = await apiFunctions.gqlquery(query);
    // print(result);
    setState(() {
      postList =
          result == null ? [] : result['postsByOrganization'].reversed.toList();
    });
  }

  Future<void> addLike(String postID) async {
    String mutation = Queries().addLike(postID);
    Map result = await apiFunctions.gqlmutation(mutation);
    print(result);
    getPosts();
  }

  Future<void> removeLike(String postID) async {
    String mutation = Queries().removeLike(postID);
    Map result = await apiFunctions.gqlmutation(mutation);
    print(result);
    getPosts();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: CustomAppBar('NewsFeed'),
        floatingActionButton: addPostFab(),
        body: postList.isEmpty
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  getPosts();
                },
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ListView.builder(
                            itemCount: postList.length,
                            itemBuilder: (context, index) {
                              return Container(
                                padding: EdgeInsets.only(top: 20),
                                child: Column(
                                  children: <Widget>[
                                    InkWell(
                                        onTap: () {
                                          pushNewScreen(
                                            context,
                                            screen: NewsArticle(
                                                post: postList[index]),
                                          );
                                        },
                                        child: Card(
                                          color: Colors.white,
                                        child: Column(
                                          children: <Widget>[
                                            Container(
                                              padding: EdgeInsets.all(5.0),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(20.0),
                                                child:  Image.asset(UIData.shoppingImage),
                                              )
                                            ),
                                            Row(
                                                children: <Widget>[
                                                  SizedBox(
                                                    width: 30,
                                                  ),
                                                  Container(
                                                      child: Text(
                                                          postList[index]['title'].toString(),
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 20.0,
                                                        ),
                                                      )
                                                  ),
                                                ]
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Row(
                                                children: <Widget>[
                                                  SizedBox(
                                                    width: 30,
                                                  ),
                                                  Container(
                                                    width: MediaQuery.of(context).size.width - 50,
                                                      
                                                      child: Text(
                                                          postList[index]["text"].toString(),
                                                        textAlign: TextAlign.justify,
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 10,
                                                        style: TextStyle(
                                                          fontSize: 16.0,
                                                        ),
                                                      )
                                                  ),
                                                ]
                                            ),
                                            Padding(
                                                padding: EdgeInsets.all(10),
                                                child: Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment.spaceAround,
                                                    children: <Widget>[
                                                      likeButton(index),
                                                      commentCounter(index),
                                                      Container(width: 80)
                                                    ])),
                                          ],
                                        ),
                                    ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                      ),
                    ],
                  ),
                )
        )
    );
  }

  Widget addPostFab() {
    return FloatingActionButton(
        backgroundColor: UIData.secondaryColor,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          pushNewScreenWithRouteSettings(context,
              screen: AddPost(), settings: RouteSettings());
        });
  }

  Widget commentCounter(index) {
    return Row(
      children: [
        Text(
          postList[index]['commentCount'].toString(),
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
        IconButton(
            icon: Icon(Icons.comment), color: Colors.grey, onPressed: () {})
      ],
    );
  }

  Widget likeButton(index) {
    return Row(
      children: [
        Text(
          postList[index]['likeCount'].toString(),
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
        IconButton(
            icon: Icon(Icons.thumb_up),
            color: Colors.grey,
            onPressed: () {
              addLike(postList[index]['_id']);
            })
      ],
    );
  }
}
