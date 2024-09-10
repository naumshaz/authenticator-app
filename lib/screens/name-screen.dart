import 'package:auth_app/screens/home-screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  //Controllers
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 0, 0, 0),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 44,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What should we call you?',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'ClashDisplay',
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: _nameController,
                  keyboardAppearance: Brightness.dark,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: Colors.white,
                  cursorWidth: 1,
                  cursorHeight: 20,
                  selectionControls: DesktopTextSelectionControls(),
                  //Input Text
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'ClashDisplay',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),

                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(top: 16, bottom: 16),
                    //Hint
                    hintText: 'John Doe',
                    hintStyle: TextStyle(
                      color: Color.fromRGBO(191, 191, 191, 0.5),
                      fontFamily: 'ClashDisplay',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    hintFadeDuration: Duration(milliseconds: 250),

                    // //Error
                    // errorBorder: UnderlineInputBorder(
                    //   borderSide: BorderSide(
                    //     color: Colors.red,
                    //   ),
                    // ),
                    // focusedErrorBorder: UnderlineInputBorder(
                    //   borderSide: BorderSide(
                    //     color: Colors.red,
                    //   ),
                    // ),
                    // //errorText: 'Enter a valid name',
                    // errorStyle: TextStyle(
                    //   color: Colors.red,
                    //   fontSize: 14,
                    // ),

                    //Borders
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white,
                      ),
                    ),

                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white,
                      ),
                    ),

                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white,
                      ),
                    ),

                    disabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.only(
                    top: 0.1,
                    left: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
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
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.isNotEmpty) {
                        HapticFeedback.selectionClick();
                        final prefs = await SharedPreferences.getInstance();
                        prefs.setBool('isFirstTime', false);
                        prefs.setString('user', _nameController.text);

                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            'NEXT',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              fontFamily: 'ClashDisplay',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          color: Colors.transparent,
                          child: Image.asset(
                            'assets/icons/arrow.png',
                            width: 30,
                            height: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
