*** Settings ***
Library    SeleniumLibrary
Library    Collections
Library    String

Test Setup      Login   ${username}    ${password}
Test Teardown   Logout

*** Variables ***

# App Info
${url}=         https://app.testproject.io/

# Login Elements
${login_banner}=        //*[@id="tp-title"]
${username_textbox}=    //*[@id="username"]
${password_textbox}=    //*[@id="password"]
${login_button}=        //*[@id="tp-sign-in"]

# Application Elements
${app_banner_logo}=     //*[@id="top-bar-row-1"]/div[1]/a/svg
${account_icon}=        //*[@id="user-popup-panel-menuitem"]/div[1]/div
${logout_button}=       //*[@id="user-popup-panel-menuitem"]/div[3]/div/div[5]/div/a
${logout_banner}=       //*[@id="tp-title"]
${job_hide_icon}=       //*[@id="mCSB_4_container"]/main/div[3]/div[2]/div/project-jobs/div/div[1]/div[1]/div
${up_to_button}=        //*[contains(text(),"Up to")]
${folder_button}=       //*[@class="tp-folder-name tp-text-ellipsis ng-binding"]
${scroll_bar}=          //*[@id="mCSB_8_dragger_vertical"]/div[1]
${scroll_bar_container}=     //*[@id="mCSB_8_dragger_vertical"]
${android_test_counter}=        /html/body/div[1]/div[1]/div/div[1]/div/div[1]/div/main/div[3]/div[2]/div/div[1]/div[1]/div[1]/div[2]/div[2]/div[1]/div[2]
${ios_test_counter}=    //*[@id="mCSB_4_container"]/main/div[3]/div[2]/div/div[1]/div[1]/div[1]/div[2]/div[3]/div[1]/div[2]
${web_test_counter}=    //*[@id="mCSB_4_container"]/main/div[3]/div[2]/div/div[1]/div[1]/div[1]/div[2]/div[4]/div[1]/div[2]
${item_container}


# Item Elements
${item_context_menu}=   //*[@class="item-content-row ng-scope"]/*/*/div[@class="tp-context-menu ng-isolate-scope"]
${download_item_button}=    //*[text()="Generated Code"]
${language_button}=     //*[@class="sdk-language-name ng-binding" and contains(.,"${language}")]
${download_button}=     //*[@class="tp-mbw-nav-button ng-binding ng-scope blue" and contains(.,"Download")]
${ready_banner}=        //span[contains(text(), "The Generated Code is ready!")]
${ok_button}=           //*[@class="tp-mbw-nav-button ng-binding ng-scope blue" and contains(.,"OK")]

*** Keywords ***

Login
    [Arguments]    ${username}    ${password}
    Open Browser    url=${url}    browser=${browser}
    Maximize Browser Window
    Wait Until Element Is Visible   ${login_banner}
    Input Text     ${username_textbox}    ${username}
    Input Text     ${password_textbox}    ${password}
    Click Element  ${login_button}
    Wait Until Element Is Visible   ${account_icon}    timeout=20
    Click Element  ${job_hide_icon}
    Sleep    10s

Logout
    Click Element  ${account_icon}
    Click Element  ${logout_button}
    Wait Until Element Is Visible   ${logout_banner}
    Close Browser

Download Test Case
    [Arguments]    ${item}
    Click Element    ${item}
    Sleep    2s
    Click Element    ${download_item_button}
    Sleep    2s
    Click Element    ${language_button}
    Wait Until Element Is Visible    ${download_button}    timeout=10s
    Click Element    ${download_button}
    Wait Until Element Is Visible    ${ready_banner}       timeout=30s
    Click Element    ${ok_button}

Download Test Cases In Folder
    [Arguments]  ${recursive}=${True}
    ${android_test_count}=  Get Text    xpath=${android_test_counter}
    ${ios_test_count}=      Get Text    xpath=${ios_test_counter}
    ${web_test_count}=      Get Text    xpath=${web_test_counter}
    ${total_count}=         Evaluate   int(${android_test_count})+int(${ios_test_count})+int(${web_test_count})

    Run Keyword and Ignore Error    Mouse Over    ${scroll_bar}
    ${con}=    Run Keyword And Return Status    Element Should Be Visible    ${scroll_bar}
    ${scrolled} =    Set Variable    ${con}
    # Scroll Down to load all tests
    WHILE   ${con}
        ${onscreen} =     Get Webelements   ${item_context_menu}
        ${onscreen_count}=    Get Length    ${onscreen}
        Log    ${onscreen_count}
        ${con}=    Evaluate  ${onscreen_count} <= (${total_count} - 1)
        Drag And Drop By Offset    ${scroll_bar}    0    ${DDOffset}
    END

    IF    ${scrolled}
        ${scroll_container}=    Get Webelement    ${scroll_bar_container}
        ${scrollTop}=     Call Method    ${scroll_container}    value_of_css_property    top
        ${scrollTop}=     Remove String    ${scrollTop}    px
        Drag And Drop By Offset    ${scroll_bar}    0    -${scrollTop}
    END


    # Download Each Test
    ${items}=    Get Webelements    ${item_context_menu}
    Log Many    @{items}
    FOR    ${item}    IN    @{items}
        Run Keyword And Ignore Error    Download Test Case    ${item}
        Execute Javascript    var element=document.querySelector('.project-test-bundle:first-child');
        ...  element.parentNode.removeChild(element);
    END

    # If recursive, go down a folder
    IF    ${recursive}
        ${folders}=    Get WebElements    ${folder_button}
        @{foldernames}=    Create List
        FOR     ${folder}    IN    @{folders}
            ${name}=    Get Text    ${folder}
        Append To List    ${foldernames}    ${name}
        END

        Log Many    @{foldernames}
        FOR     ${folder}    IN    @{foldernames}
            Wait Until Element Is Visible    //span[text()="${folder}"]
            Click Element    //span[text()="${folder}"]
            Download Test Cases In Folder
        END

        ${subfolder}=    Run Keyword And Return Status    Element Should Be Visible    ${up_to_button}
        IF    ${subfolder}
            Click Element    ${up_to_button}
        END
    END


*** Test Cases ***
Download All
    Download Test Cases In Folder

