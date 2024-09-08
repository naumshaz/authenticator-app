import 'dart:convert';
import 'dart:ui';
import 'package:auth_app/models/account.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //Controllers
  TextEditingController _searchController = TextEditingController();

  //Strings
  String user = '';

  //Lists
  List<Account> accounts = [];

  @override
  void initState() {
    super.initState();
    getName();
    _loadAccounts();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(0.2 * screenHeight), // Adjust height as needed
        child: AppBar(
          backgroundColor: Colors.black,
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HelloDialog(),
                SearchBar(),
              ],
            ),
          ),
        ),
      ),
      body: Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: 25, right: 25),
          child: ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.only(
                      top: 5,
                      bottom: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${account.type}: ${account.name}',
                              style: TextStyle(
                                color: Color(0xFF909090),
                                fontFamily: 'ClashDisplay',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${account.otp}',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'ClashDisplay',
                                fontSize: 36,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container() //Add Timer Indicator here
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            padding: EdgeInsets.only(top: 2.5, left: 3, right: 1),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(100),
              border: Border(
                bottom: BorderSide(
                  width: 0.05,
                  color: Colors.white,
                ),
                left: BorderSide(
                  width: 0.05,
                  color: Colors.white,
                ),
                right: BorderSide(
                  width: 1,
                  color: Colors.white,
                ),
                top: BorderSide(
                  width: 1,
                  color: Colors.white,
                ),
              ),
            ),
            child: FloatingActionButton(
              onPressed: () {
                _showAddOptions(context);
                //_addAccount();
              },
              shape: CircleBorder(),
              backgroundColor: Colors.white,
              child: Icon(Icons.add, color: Colors.black),
              tooltip: 'Add',
            ),
          ),
        ),
      ),
    );
  }

  Padding SearchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          border: Border(
            top: BorderSide(
              color: Colors.white,
              width: 0.75,
            ),
            right: BorderSide(
              color: Colors.white,
              width: 0.75,
            ),
            bottom: BorderSide(
              color: Colors.white,
              width: 3, // No border
            ),
            left: BorderSide(
              color: Colors.white,
              width: 0.75, // No border
            ),
          ),
        ),
        child: TextField(
          controller: _searchController,
          keyboardAppearance: Brightness.dark,
          cursorColor: Colors.white,
          cursorWidth: 1,
          cursorHeight: 20,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'ClashDisplay',
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            contentPadding:
                EdgeInsets.only(top: 12, bottom: 12, left: 15, right: 15),
            hintText: 'Search...',
            hintStyle: TextStyle(
              color: Color.fromRGBO(255, 255, 255, 1),
              fontFamily: 'ClashDisplay',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none, // Removes default border
          ),
        ),
      ),
    );
  }

  Column HelloDialog() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(top: 10, bottom: 10),
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Hello ',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'ClashDisplay',
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    '👋🏻',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'ClashDisplay',
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(0),
                child: Text(
                  '${user}',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'ClashDisplay',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Future<void> getName() async {
    final prefs = await SharedPreferences.getInstance();
    user = prefs.getString('user') ?? 'User';
    setState(() {});
  }

  Future<void> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accountsJson = prefs.getString('accounts');
    if (accountsJson != null) {
      final List<dynamic> accountsList = json.decode(accountsJson);
      setState(() {
        accounts = accountsList.map((item) => Account.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String accountsJson =
        json.encode(accounts.map((a) => a.toJson()).toList());
    await prefs.setString('accounts', accountsJson);
  }

  void _showAddOptions(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierLabel: 'Dismiss',
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  //color: const Color.fromARGB(255, 221, 94, 94),
                  borderRadius: BorderRadius.circular(10),
                ),
                width: screenWidth * 0.85,
                height: 1.5 * (120 / 390) * screenWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: (120 / 390) * screenWidth,
                            height: (120 / 390) * screenWidth,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Image.asset(
                              'assets/icons/keyboard.png',
                              width: 62,
                              height: 62,
                            ),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Text(
                            'Setup Key',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'ClashDisplay',
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: (35 / 390) * screenWidth,
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          Container(
                            width: (120 / 390) * screenWidth,
                            height: (120 / 390) * screenWidth,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Image.asset(
                              'assets/icons/QR.png',
                              width: 62,
                              height: 62,
                            ),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Text(
                            'QR Code',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'ClashDisplay',
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0))
              .animate(anim), // Slide up transition
          child: child,
        );
      },
    );
  }

  void _addAccount() {
    setState(() {
      accounts.add(Account(
        type: 'Type ${accounts.length + 1}',
        name: 'Account ${accounts.length + 1}',
        otp: '123456',
      ));
      _saveAccounts();
    });
  }
}
