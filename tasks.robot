*** Settings ***
Documentation       Template robot main suite.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the pdf receipt.
...                 Creates ZIP archive of the receipts and the images.
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables            
Library             RPA.PDF
Library             XML
Library             RPA.Archive

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download orders file
    Read orders from csv
    Archive PDF Files

*** Keywords ***

Open the robot order website
    Open Available Browser      https://robotsparebinindustries.com/#/robot-order

Download orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}


Export screenshot to pdf
    [Arguments]    ${orderNumber}
    ${order_receipt_html}=    Get Element Attribute    receipt    outerHTML    
    Html To Pdf    ${order_receipt_html}    ${OUTPUT_DIR}${/}receipt_${orderNumber}.pdf
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${orderNumber}.png
    ${receiptPDF}=    Open Pdf    ${OUTPUT_DIR}${/}receipt_${orderNumber}.pdf
    ${robotPNG}=    Create List        ${OUTPUT_DIR}${/}${orderNumber}.png
    ...    ${OUTPUT_DIR}${/}receipt_${orderNumber}.pdf
    Add Files To Pdf    ${robotPNG}    ${OUTPUT_DIR}${/}receipt_${orderNumber}.pdf
    Close Pdf    ${receiptPDF}
    

    

Fill and submit order
    [Arguments]    ${order}   
    Log    ${order}[Body]
    ${orderNumber}=    Set Variable    ${order}[Order number]
    Click Button    OK
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://label[contains(.,'3. Legs:')]/../input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    id:preview
    Sleep    5s
    Click Button    order
    ${is_order_another_element_existing}=    Set Variable    ${False}
    
    WHILE    ${is_order_another_element_existing} == $False
        TRY
            Wait Until Element Is Visible    id:order-another
            Export screenshot to pdf    ${orderNumber}
            Click Button    id:order-another
            ${is_order_another_element_existing}=    Set Variable    ${True}
        EXCEPT
            Click Button    order
            ${is_order_another_element_existing}=    Set Variable    ${False}
        END      
    END 

    
          
Read orders from csv
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Fill and submit order    ${order}
        
    END

Archive PDF Files
    Archive Folder With Zip    ${OUTPUT_DIR}   ${OUTPUT_DIR}${/}receipts.zip    recursive=True  include=*.pdf  exclude=/.*    
    
    


    

