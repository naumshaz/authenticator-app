import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:auth_app/models/account.dart';
import 'package:base32/base32.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:otp/otp.dart';
import 'package:qr_bar_code_scanner_dialog/qr_bar_code_scanner_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _accTypeController = TextEditingController();
  final TextEditingController _accNameController = TextEditingController();
  final TextEditingController _setupKeyController = TextEditingController();

  //Strings
  String user = '';

  //Lists
  List<Account> accounts = [];
  List<Account> _searchedItems = [];
  List<Color> _blinks = [
    Color.fromRGBO(255, 255, 255, 1),
    Color.fromRGBO(255, 255, 255, 0.8)
  ];

  //Others
  FocusNode _focusNode = FocusNode();
  final _qrBarCodeScannerDialogPlugin = QrBarCodeScannerDialog();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getName();
    _loadAccounts();
    _startTimer();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _searchController.text = '';
        _searchedItems = accounts;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _searchItems(String query) {
    List<Account> filteredItems = accounts.where((item) {
      return item.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _searchedItems = filteredItems;
    });
  }

  bool _validateSecretKey(String key) {
    try {
      base32.decode(key);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.1),
        child: AppBar(
          backgroundColor: Colors.black,
          flexibleSpace: Container(),
        ),
      ),
      body: Column(
        children: [
          HelloDialog(),
          SearchBar(),
          accounts.isEmpty ? getStartedText(screenHeight) : buildAccountsList(),
        ],
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
                HapticFeedback.selectionClick();
                _showAddOptions(context);
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

  SizedBox getStartedText(double screenHeight) {
    return SizedBox(
      height: 0.55 * screenHeight,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Text(
            "Tap '+' to get started!",
            style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: const Color.fromRGBO(255, 255, 255, 0.5)),
          ),
        ),
      ),
    );
  }

  Expanded buildAccountsList() {
    double screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: 25, right: 25),
        child: SlidableAutoCloseBehavior(
          child: ListView.builder(
            itemCount: _searchedItems.length,
            itemBuilder: (context, index) {
              final account = _searchedItems[index];

              final otpCode = OTP.generateTOTPCodeString(
                account.key,
                DateTime.now().millisecondsSinceEpoch,
                length: 6,
                interval: account.otpInterval,
                algorithm: Algorithm.SHA256,
                isGoogle: true,
              );

              return Slidable(
                key: Key(account.key),
                endActionPane: ActionPane(
                  motion: DrawerMotion(),
                  dismissible: DismissiblePane(
                    onDismissed: () {_deleteAccount(account);},
                  ),
                  children: [
                    SlidableAction(
                      onPressed: (context) => _showEditOption(context, account),
                      backgroundColor: Color.fromRGBO(96, 96, 96, 0.75),
                      icon: Icons.edit_sharp,
                      foregroundColor: Colors.white,
                      autoClose: true,
                    ),
                    SlidableAction(
                      onPressed: (context) => showRemoveAlert(context, account),
                      backgroundColor: Color.fromRGBO(255, 82, 82, 1),
                      icon: Icons.delete_outlined,
                      foregroundColor: Colors.white,
                      autoClose: true,
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: otpCode));
                        HapticFeedback.mediumImpact();
                        showCopiedAlert(context);
                      },
                      splashColor: Color(0xFF606060).withOpacity(0.25),
                      highlightColor: Color(0xFF606060).withOpacity(0.1),
                      child: Container(
                        padding: EdgeInsets.only(top: 13, bottom: 8, right: 5),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFF909090)),
                          ),
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
                                  '${otpCode.substring(0, 3)} ${otpCode.substring(3, 6)}',
                                  style: TextStyle(
                                    color: OTP.remainingSeconds() > 5
                                        ? Colors.white
                                        : _blinks[(OTP.remainingSeconds() % 2)],
                                    fontFamily: 'ClashDisplay',
                                    fontSize: 36,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 25,
                              width: 25,
                              child: CircularProgressIndicator(
                                value: 1 -
                                    (OTP.remainingSeconds() /
                                        account.otpInterval),
                                color: Color(0xFF505050),
                                backgroundColor: OTP.remainingSeconds() > 5
                                    ? Colors.white
                                    : _blinks[(OTP.remainingSeconds() % 2)],
                                strokeWidth: 3,
                              ),
                            )
                            // Text(
                            //   '${OTP.remainingSeconds()}',
                            //   style: TextStyle(
                            //     color: Colors.white,
                            //     fontFamily: 'ClashDisplay',
                            //     fontSize: 18,
                            //     fontWeight: FontWeight.w500,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Padding SearchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 10, left: 20, right: 20),
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
          focusNode: _focusNode,
          keyboardAppearance: Brightness.dark,
          cursorColor: Colors.white,
          cursorWidth: 1,
          cursorHeight: 20,
          onChanged: (value) {
            _searchItems(value);
          },
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

  Padding HelloDialog() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 0),
      child: Column(
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
      ),
    );
  }

  Future<void> _getName() async {
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
        _searchedItems = accounts;
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
                      onTap: () {
                        Navigator.of(context).pop();
                        _accNameController.text = '';
                        _accTypeController.text = '';
                        _setupKeyController.text = '';
                        _showSetupKeyOption(context);
                      },
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
                      onTap: () {
                        Navigator.of(context).pop();
                        _qrBarCodeScannerDialogPlugin.getScannedQrBarCode(
                          context: context,
                          onCode: (code) {
                            if (code == null) {
                            } else {
                              if (code.contains('/')) {
                                if (code.split('/').length == 3 &&
                                    _validateSecretKey(code.split('/')[2])) {
                                  _addAccount(code.split('/')[0],
                                      code.split('/')[1], code.split('/')[2]);
                                  HapticFeedback.mediumImpact();
                                  _loadAccounts();
                                }
                              }
                            }
                          },
                        );
                      },
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

  void _showSetupKeyOption(BuildContext context) {
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
                  color: Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(10),
                ),
                width: screenWidth * 0.85,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 15,
                    bottom: 15,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Type',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _accTypeController,
                          keyboardAppearance: Brightness.dark,
                          textCapitalization: TextCapitalization.words,
                          cursorColor: Color(0xFF000000),
                          cursorWidth: 1,
                          cursorHeight: 20,
                          selectionControls: DesktopTextSelectionControls(),
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                              top: 16,
                              bottom: 16,
                              left: 10,
                              right: 10,
                            ),
                            fillColor: Color(0xFFEBEBEB),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                width: 2,
                                color: (_setupKeyController.text.length > 0)
                                    ? Colors.transparent
                                    : Colors.black,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                          ),
                        ),
                        SizedBox(height: (20 / 390) * screenWidth),
                        Text(
                          'Account Name',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _accNameController,
                          keyboardAppearance: Brightness.dark,
                          cursorColor: Color(0xFF000000),
                          cursorWidth: 1,
                          cursorHeight: 20,
                          selectionControls: DesktopTextSelectionControls(),
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                              top: 16,
                              bottom: 16,
                              left: 10,
                              right: 10,
                            ),
                            fillColor: Color(0xFFEBEBEB),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: (_accNameController.text.length > 0)
                                    ? Colors.transparent
                                    : Colors.black,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                          ),
                        ),
                        SizedBox(height: (20 / 390) * screenWidth),
                        Text(
                          'Setup Key',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _setupKeyController,
                          keyboardAppearance: Brightness.dark,
                          cursorColor: Color(0xFF000000),
                          cursorWidth: 1,
                          cursorHeight: 20,
                          selectionControls: DesktopTextSelectionControls(),
                          style: TextStyle(
                            color: Color(0xFF000000),
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                              top: 16,
                              bottom: 16,
                              left: 10,
                              right: 10,
                            ),
                            fillColor: Color(0xFFEBEBEB),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                width: 2,
                                color: (_setupKeyController.text.length > 0)
                                    ? Colors.transparent
                                    : Colors.black,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                          ),
                        ),
                        SizedBox(height: 35),
                        SizedBox(
                          width: (300 / 390 * screenWidth),
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_accTypeController.text.isNotEmpty &&
                                  _accNameController.text.isNotEmpty &&
                                  _setupKeyController.text.isNotEmpty) {
                                if (_validateSecretKey(
                                    _setupKeyController.text)) {
                                  _addAccount(
                                    _accTypeController.text,
                                    _accNameController.text,
                                    _setupKeyController.text,
                                  );
                                  HapticFeedback.mediumImpact();
                                  _loadAccounts();
                                  setState(() {
                                    for (var account in accounts) {
                                      account.lastOtpGenerationTime =
                                          DateTime.now().millisecondsSinceEpoch;
                                    }
                                  });
                                  Navigator.of(context).pop();
                                } else {
                                  _setupKeyController.text = '';
                                }
                              }
                            },
                            child: Text(
                              'Add',
                              style: TextStyle(
                                fontFamily: 'ClashDisplay',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0))
              .animate(anim),
          child: child,
        );
      },
    );
  }

  void _showEditOption(BuildContext context, Account account) {
    _accNameController.text = account.name;
    _accTypeController.text = account.type;
    _setupKeyController.text = account.key;
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
                  color: Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(10),
                ),
                width: screenWidth * 0.85,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 15,
                    bottom: 15,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Type',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _accTypeController,
                          keyboardAppearance: Brightness.dark,
                          textCapitalization: TextCapitalization.words,
                          cursorColor: Color(0xFF000000),
                          cursorWidth: 1,
                          cursorHeight: 20,
                          selectionControls: DesktopTextSelectionControls(),
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                              top: 16,
                              bottom: 16,
                              left: 10,
                              right: 10,
                            ),
                            fillColor: Color(0xFFEBEBEB),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                width: 2,
                                color: (_setupKeyController.text.length > 0)
                                    ? Colors.transparent
                                    : Colors.black,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                          ),
                        ),
                        SizedBox(height: (20 / 390) * screenWidth),
                        Text(
                          'Account Name',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _accNameController,
                          keyboardAppearance: Brightness.dark,
                          cursorColor: Color(0xFF000000),
                          cursorWidth: 1,
                          cursorHeight: 20,
                          selectionControls: DesktopTextSelectionControls(),
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                              top: 16,
                              bottom: 16,
                              left: 10,
                              right: 10,
                            ),
                            fillColor: Color(0xFFEBEBEB),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: (_accNameController.text.length > 0)
                                    ? Colors.transparent
                                    : Colors.black,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                          ),
                        ),
                        SizedBox(height: (20 / 390) * screenWidth),
                        Text(
                          'Setup Key',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _setupKeyController,
                          keyboardAppearance: Brightness.dark,
                          cursorColor: Color(0xFF000000),
                          cursorWidth: 1,
                          cursorHeight: 20,
                          selectionControls: DesktopTextSelectionControls(),
                          style: TextStyle(
                            color: Color(0xFF000000),
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                              top: 16,
                              bottom: 16,
                              left: 10,
                              right: 10,
                            ),
                            fillColor: Color(0xFFEBEBEB),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                width: 2,
                                color: (_setupKeyController.text.length > 0)
                                    ? Colors.transparent
                                    : Colors.black,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                          ),
                        ),
                        SizedBox(height: 35),
                        SizedBox(
                          width: (300 / 390 * screenWidth),
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_accTypeController.text.isNotEmpty &&
                                  _accNameController.text.isNotEmpty &&
                                  _setupKeyController.text.isNotEmpty) {
                                if (_validateSecretKey(
                                    _setupKeyController.text)) {
                                  _deleteAccount(account);
                                  _addAccount(
                                    _accTypeController.text,
                                    _accNameController.text,
                                    _setupKeyController.text,
                                  );
                                  HapticFeedback.mediumImpact();
                                  _loadAccounts();
                                  setState(() {
                                    for (var account in accounts) {
                                      account.lastOtpGenerationTime =
                                          DateTime.now().millisecondsSinceEpoch;
                                    }
                                  });
                                  Navigator.of(context).pop();
                                } else {
                                  _setupKeyController.text = '';
                                }
                              }
                            },
                            child: Text(
                              'Submit Changes',
                              style: TextStyle(
                                fontFamily: 'ClashDisplay',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0))
              .animate(anim),
          child: child,
        );
      },
    );
  }

  void showCopiedAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Dialog(
            alignment: Alignment.bottomCenter,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: IntrinsicHeight(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 5,
                        sigmaY: 5,
                      ),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.05),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(255, 255, 255, 0.15),
                            Color.fromRGBO(255, 255, 255, 0.05),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: Text(
                          'Copied',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(Duration(milliseconds: 600), () {
      Navigator.of(context, rootNavigator: true).pop();
    });
  }

  void showRemoveAlert(BuildContext context, Account account) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Dialog(
            alignment: Alignment.center,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: IntrinsicHeight(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 5,
                        sigmaY: 5,
                      ),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.05),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(255, 255, 255, 0.15),
                            Color.fromRGBO(255, 255, 255, 0.05),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 25, bottom: 20, left: 25, right: 25),
                      child: Column(
                        children: [
                          Center(
                            child: Text(
                              "Do you really want to remove ${account.type}?",
                              style: TextStyle(
                                fontFamily: 'ClashDisplay',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _deleteAccount(account);
                                },
                                child: Text(
                                  'Remove',
                                  style: TextStyle(
                                    fontFamily: 'ClashDisplay',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontFamily: 'ClashDisplay',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            ],
                          )
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
    );
  }

  void _addAccount(String type, String name, String setupKey) {
    setState(() {
      accounts.add(Account(
        type: type,
        name: name,
        key: setupKey,
        lastOtpGenerationTime: DateTime.now().millisecondsSinceEpoch,
      ));
      _saveAccounts();
    });
  }

  void _deleteAccount(Account account) {
    setState(() {
      accounts.remove(account);
      _saveAccounts();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }
}
