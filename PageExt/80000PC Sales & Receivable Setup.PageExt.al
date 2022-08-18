pageextension 80000 "PC Sales & Rec Setup Ext" extends "Sales & Receivables Setup"
{
    layout
    {
        addafter("Number Series")
        {
            group("Pet Culture")
            {
                Group(Shopify)
                {
                    Group("Production Shopify")
                    {
                        field("Shopify Connect URL"; rec."Shopify Connnect Url")
                        {
                            ApplicationArea = All;
                            ExtendedDatatype = URL;
                            ToolTip = 'Connect Url to access Shopify';
                            ShowMandatory = true;
                        }
                        field("Shopify API Key"; rec."Shopify API Key")
                        {
                            ApplicationArea = All;
                            ToolTip = 'API Key to access Shopify';
                            ShowMandatory = true;
                        }
                        field("Shopify Password"; rec."Shopify Password")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Password to access Shopify';
                            ExtendedDatatype = Masked;
                            ShowMandatory = true;
                            trigger OnAssistEdit()
                            begin
                                Message(StrSubstNo('%1', rec."Shopify Password"))
                            end;
                        }
                    }
                    Group("Development Shopify")
                    {
                        field("Dev Shopify Connect URL"; rec."Dev Shopify Connnect Url")
                        {
                            ApplicationArea = All;
                            ExtendedDatatype = URL;
                            ToolTip = 'Connect Url to access Dev Shopify';
                            ShowMandatory = true;
                        }
                        field("Dev Shopify API Key"; rec."Dev Shopify API Key")
                        {
                            ApplicationArea = All;
                            ToolTip = 'API Key to access Dev Shopify';
                            ShowMandatory = true;
                        }
                        field("Dev Shopify Password";rec."Dev Shopify Password")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Password to access Dev Shopify';
                            ExtendedDatatype = Masked;
                            ShowMandatory = true;
                            trigger OnAssistEdit()
                            begin
                                Message(StrSubstNo('%1', rec."Dev Shopify Password"))
                            end;
                         }
                    }
                    field("Shopify Acces Mode"; rec."Use Shopify Dev Access")
                    {
                        ApplicationArea = All;
                    }     
                    field("A";'TEST CONNNECTION')
                    {
                        ShowCaption = false; 
                        ApplicationArea = All;
                        Style = Strong;
                        trigger OnDrillDown()
                        var  
                            cu:Codeunit "PC Shopify Routines";
                            flg:array[3] of Boolean;
                        begin
                            rec.modify;
                            CurrPage.Update(True);
                            Commit;
                            rec.Get;
                            Flg[1] := (rec."Shopify Connnect Url" <> '')  
                                    ANd (rec."Shopify API Key" <> '')
                                    AND (rec."Shopify Password" <> '');
                            Flg[2] := (rec."Dev Shopify Connnect Url" <> '')  
                                    ANd (rec."Dev Shopify API Key" <> '')
                                    AND (rec."Dev Shopify Password" <> '');
                            Flg[3] := Flg[1] And Not rec."Use Shopify Dev Access";
                            If Not Flg[3] then Flg[3] := Flg[2] And rec."Use Shopify Dev Access";         
                            If Flg[3] then        
                            begin
                            if Confirm('Test Shopify Connection using supplied parameters now?',true) then
                                begin
                                    If Cu.Shopify_Test_Connection() then
                                        Message('Connect Successfull')
                                    else
                                        Message('Connect Unsuccessfull');    
                                end;    
                            end
                            else
                                Message('Please provide all Shopify parameters.');;                       
                        end;
                    }
                    Group(Orders)
                    {
                        field("Shopify Order No. Offset"; rec."Shopify Order No. Offset")
                        {
                            ApplicationArea = All;
                        }
                        field("Bypass Date Filter";rec."Bypass Date Filter")
                        {
                            ApplicationArea = All;
                        }
                        field("Refund Order Lookback Period";rec."Refund Order Lookback Period")
                        {
                            ApplicationArea = All;
                        }
                    }
                    Group(Exceptions)
                    {
                        field("Exception Email Address"; rec."Exception Email Address")
                        {
                            ApplicationArea = All;
                            ExtendedDatatype = EMail;
                            trigger OnAssistEdit()
                            var 
                                cu:Codeunit "PC Shopify Routines";
                            begin
                                rec.Modify;
                                Commit;
                                Rec.Get;
                                If Confirm('Send Test Email', true) then
                                begin
                                    If Cu.Send_Email_Msg('Test Email','This is a test',True,'') then
                                        Message('Email Sent Successfully')
                                    else
                                        Message('Failed To Send Email');
                                end;  
                            end;
                        }
                    }
                }  
                Group(FulFilio)
                {
                    Group("Production Fulfilio")
                    {
                        field("FulFilo Connect URL"; rec."FulFilio Connnect Url")
                        {
                            ApplicationArea = All;
                            ExtendedDatatype = URL;
                            ToolTip = 'Connect Url to access FulFilio';
                            ShowMandatory = true;
                        }
                        field("FulFilio Store ID"; rec."FulFilio Store ID")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Store ID to access FulFilio';
                            ShowMandatory = true;
                        }
                        field("FulFilio Client ID"; rec."FulFilio Client ID")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Client ID to access FulFilio';
                            ShowMandatory = true;
                        }
                        field("FulFilio Client Secret"; rec."FulFilio Client Secret")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Client Secret to access FulFilio';
                            ShowMandatory = true;
                        }
                        field("FulFilio UserName"; rec."FulFilio UserName")
                        {
                            ApplicationArea = All;
                            ToolTip = 'UserName to access FulFilio';
                            ShowMandatory = true;
                        }
                        field("FulFilio Password"; rec."FulFilio Password")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Password to access FulFilio';
                            ExtendedDatatype = Masked;
                            ShowMandatory = true;
                            trigger OnAssistEdit()
                            begin
                                Message(StrSubstNo('%1', rec."FulFilio Password"))
                            end;
                         }
                    }
                    Group("Development Fulfilio")
                    {
                        field("Dev FulFilo Connect URL"; rec."Dev FulFilio Connnect Url")
                        {
                            ApplicationArea = All;
                            ExtendedDatatype = URL;
                            Caption = 'Dev FulFilio Connect URL';
                            ToolTip = 'Connect Url to access Dev FulFilio';
                            ShowMandatory = true;
                        }
                        field("Dev FulFilio Store ID"; rec."Dev FulFilio Store ID")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Store ID to access Dev FulFilio';
                            ShowMandatory = true;
                        }
                        field("Dev FulFilio Client ID"; rec."Dev FulFilio Client ID")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Client ID to access Dev FulFilio';
                            ShowMandatory = true;
                        }
                        field("Dev FulFilio Client Secret"; rec."Dev FulFilio Client Secret")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Client Secret to access Dev FulFilio';
                            ShowMandatory = true;
                        }
                        field("Dev FulFilio UserName"; rec."Dev FulFilio UserName")
                        {
                            ApplicationArea = All;
                            ToolTip = 'UserName to access Dev FulFilio';
                            ShowMandatory = true;
                        }
                        field("Dev FulFilio Password";rec."Dev FulFilio Password")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Password to access Dev FulFilio';
                            ExtendedDatatype = Masked;
                            ShowMandatory = true;
                            trigger OnAssistEdit()
                            begin
                                Message(StrSubstNo('%1', rec."Dev FulFilio Password"))
                            end;
                          }
                    }
                    field("Fulfilo Acces Mode"; rec."Use Fulfilo Dev Access")
                    {
                        ApplicationArea = All;
                        Caption = 'Fulfilio Acces Mode';
                    }     
                    field("B";'TEST CONNNECTION')
                    {
                        ShowCaption = false; 
                        ApplicationArea = All;
                        Style = Strong;
                        trigger OnDrillDown()
                        var  
                            cu:Codeunit "PC Fulfilio Routines";
                            flg:array[3] of Boolean;
                        begin
                            CurrPage.Update(True);
                            Commit;
                            rec.Get;
                            Flg[1] := (rec."FulFilio Connnect Url" <> '')  
                                    ANd (rec."FulFilio Store ID" <> 0)
                                    AND (rec."FulFilio Client ID" <> '') 
                                    AND (rec."FulFilio Client Secret" <> '') 
                                    AND (rec."FulFilio UserName" <> '') 
                                    AND (rec."FulFilio Password" <> '');
                            Flg[2] := (rec."Dev FulFilio Connnect Url" <> '')  
                                    ANd (rec."Dev FulFilio Client ID" <> '') 
                                    AND (rec."Dev FulFilio Client Secret" <> '') 
                                    AND (rec."Dev FulFilio UserName" <> '') 
                                    AND (rec."Dev FulFilio Password" <> '');
                            Flg[3] := Flg[1] And Not rec."Use FulFilo Dev Access";
                            If Not Flg[3] then Flg[3] := Flg[2] And rec."Use Fulfilo Dev Access";         
                            If Flg[3] then        
                            begin
                            if Confirm('Test FulFilio Connection using supplied parameters now?',true) then
                                begin
                                    If Cu.FulFilo_Login_Connection() then
                                        Message('Connect Successfull')
                                    else
                                        Message('Connect Unsuccessfull');    
                                end;    
                            end
                            else
                                Message('Please provide all FulFilio parameters.');;                       
                        end;
                    }    
                }
                Group(EDI)
                {
                    field("SPS Client ID"; rec."SPS Client ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Client ID to access SPS';
                        ShowMandatory = true;
                    }
                    field("SPS Secret Key"; rec."SPS Secret Key")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Secret ID to access SPS';
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        trigger OnAssistEdit()
                        begin
                            Message(StrSubstNo('%1', rec."SPS Secret Key"));
                        end;
                    }
                    field("C";'TEST CONNNECTION')
                    {
                        ShowCaption = false; 
                        ApplicationArea = All;
                        Style = Strong;
                        trigger OnDrillDown()
                        var  
                            cu:Codeunit "PC EDI Routines";
                        begin
                            CurrPage.Update(True);
                            Commit;
                            rec.Get;
                            If (Rec."SPS Client ID" <> '') AND (Rec."SPS Secret Key" <> '') 
                                AND (Rec."SPS EDI Base Folder Path" <> '') AND (Rec."SPS EDI Out Folder" <> '')
                                AND (Rec."SPS EDI In Folder" <> '') And (Rec."SPS EDI Auth Token Folder Path" <> '') then        
                            begin
                                if Confirm('Test EDI Connection using supplied parameters now?',true) then
                                begin
                                    If Cu.Get_EDI_Access_Token(true) then
                                        Message('Connect Successfull')
                                    else
                                        Message('Connect Unsuccessfull');    
                                end;    
                            end
                            else
                                Message('Please provide all EDI parameters.');;                       
                        end;
                    }
                    field("EDI Exception Email Address";rec."EDI Exception Email Address")
                    {
                        ApplicationArea = All;
                        ExtendedDatatype = EMail;
                        trigger OnAssistEdit()
                        var 
                            cu:Codeunit "PC Shopify Routines";
                        begin
                            rec.Modify;
                            Commit;
                            Rec.Get;
                            If Confirm('Send Test Email', true) then
                            begin
                                If Cu.Send_Email_Msg('Test Email','This is a test',False,'') then
                                    Message('Email Sent Successfully')
                                else
                                    Message('Failed To Send Email');
                            end;  
                        end;
                    }
                    Field("SPS EDI Auth Token Folder Path"; rec."SPS EDI Auth Token Folder Path")
                    {
                        ApplicationArea = All;
                    }
                     Field("SPS EDI Base Folder Path"; rec."SPS EDI Base Folder Path")
                    {
                        ApplicationArea = All;
                    }
                    field("SPS EDI Out Folder"; rec."SPS EDI Out Folder")
                    {
                        ApplicationArea = All;
                    }
                    Field("SPS EDI In Folder"; rec."SPS EDI In Folder")
                    {
                        ApplicationArea = All;
                    }
                    Field("EDI Order Value Tolerance %"; rec."EDI Order Value Tolerance %")
                    {
                        ApplicationArea = All;
                    }
                    Field("EDI Line Value Tolerance %"; rec."EDI Line Value Tolerance %")
                    {
                        ApplicationArea = All;
                    }
                    Field("EDI Line Qty Tolerance %"; rec."EDI Line Qty Tolerance %")
                    {
                        ApplicationArea = All;
                    }
                    Field("EDI Delivery Date Tolerance Days"; rec."EDI Del Date Tolerance Days")
                    {
                        ApplicationArea = All;
                        Caption = 'EDI Delivery Date Tolerance Days';
                    }
                }
                group(Purchasing)
                {
                    Field("PO CC email Address";rec."PO CC email Address")
                    {
                        ApplicationArea = All;
                    }
                }
                group(Gmail)
                {
                    Field("Gmail Account Email Password";rec."Gmail Acc Email Password")
                    {
                        ApplicationArea = All;
                        ExtendedDatatype = Masked;
                        trigger OnAssistEdit()
                        begin
                            Message(StrSubstNo('%1', rec."Gmail Acc Email Password"));
                        end;
                    }
                     Field("Gmail Operation Email Password";rec."Gmail Ops Email Password")
                    {
                        ApplicationArea = All;
                        ExtendedDatatype = Masked;
                        trigger OnAssistEdit()
                        begin
                            Message(StrSubstNo('%1', rec."Gmail Ops Email Password"));
                        end;
                    }
                }
                Group(Debug)
                {
                    Field("Debug Start Date";rec."Debug Start Date")
                    {
                        ApplicationArea = All;
                    }
                    Field("Debug End Date";rec."Debug End Date")
                    {
                        ApplicationArea = All;
                    }
                }
            }
        }        
    }
    actions
    {   
        addlast(Processing)
        {
            action(MSGS)
            {
                ApplicationArea = all;
                Caption = 'Reset the Transfer Flag';
                trigger OnAction()
                var
                    Item:array[2] of record Item;
                    rel:record "PC Shopify Item Relations";
                begin
                
                        Item[1].Reset;
                        Item[1].Setrange("Shopify Transfer Flag",TRUE);
                        If Item[1].Findset Then Item[1].ModifyAll("Shopify Transfer Flag",False,False);
                        /*


                        Item[1].Setrange(Type,Item[1].type::"Non-Inventory");
                        If Item[1].findset then 
                        repeat
                            Item[1]."CRM Shopify Product ID" := Item[1]."Shopify Product ID";
                            Item[1]."Shopify Transfer Flag" := TRUE;
                            Rel.Reset;
                            Rel.Setrange("Parent Item No.",Item[1]."No.");
                            If Rel.findset then
                            repeat
                                Item[2].Get(Rel."Child Item No.");
                                Item[2]."CRM Shopify Product ID" := Item[1]."Shopify Product ID";
                                Item[2]."Shopify Transfer Flag" := false;
                                Item[2].Modify(false);
                            until rel.next = 0;
                            Item[1]."Shopify Transfer Flag" := F;

                            Item[1].modify(false);    
                        until Item[1].next = 0;
                        */    
                    end;
            }
               
            action(MSGS2)
            {
                ApplicationArea = all;
                Caption = 'Clear Shopify';
                trigger OnAction()
                var
                   Cu:Codeunit "PC Shopify Routines";
                begin
                    if Confirm('Are you absolutely sure you wish to clear Shopify now?',False) THen                     
                        Cu.Clean_Shopify();
                end;
            }   
 /*           action(MSGS3)
            {
                ApplicationArea = all;
                Caption = 'Copy Cost';
                trigger OnAction()
                var
                    PCPrice:Record "PC Purchase Pricing";
                    PPrice: Record "Purchase Price";
                    Item:record Item;
                begin
                    PCPRICE.reset;
                    If PCPrice.findset then PCPrice.Deleteall;
                    PPrice.reset;
                    If PPRice.findset then
                    repeat
                        PCPrice.init;
                        PCPrice."Item No." := PPrice."Item No.";
                        PCPrice."Supplier Code" := PPrice."Vendor No.";
                        PCPrice."Unit Cost" := PPrice."Direct Unit Cost";
                        PCPrice."Start Date" := PPrice."Starting Date";
                        PCPrice."End Date" := PPrice."Ending Date";
                        PCPrice.insert;        
                     until PPRice.next = 0;    
                    Item.reset;
                    Item.Setfilter("No.",'SKU-9*');
                    If Item.Findset then
                    repeat
                        Item.Update_Parent(); 
                    Until Item.next = 0;       
                    Reb.Reset;
                    If Reb.findset then
                    repeat
                        if Item.Get(Reb."Child Item No.") then
                        begin
                            Item."Is Child Flag" := True;
                            Item.Modify(false);
                        end;     
                    Until Reb.next = 0;
                end;
                
            } */
            action(MSGS6)
            {
                ApplicationArea = all;
                Caption = 'Test';
                trigger OnAction()
                var
                    Cu:Codeunit Test;
                    CU2:Codeunit "PC Reconcillations";
                    Excp:record "PC Shopify Order Exceptions";
                    Cu1:Codeunit "PC Shopify Routines";
                    PO:record "Purchase Header";
                    Ven:record Vendor;
                    Pg:page "PC Reverse Apply Selections";
                    Sel:Record Item;
                    Em:text;

                begin
                    //CU1.Process_Out_Of_Stock_Shopify_Items();
                    //exit;
                    Cu.Fix_con();
                    Cu.Fix_Shopify_Dates();
                    Exit;
                    //pg.LookupMode := true;
                    //Pg.SetApplyType(1);
                    //If Pg.RunModal() = Action::LookupOK then
                    //begin
                        //Pg.GetRecord(Sel);
                        //If Confirm(strsubstno('Proceed using %1 document now?',Sel."No."),true) then
                        Cu2.Reverse_Reconcillation_TransactionsEX('');
                    //end;
                    exit;
                    CU2.Reverse_Reconcillation_Transactions('');
                    //Cu.Fix_Accounts();
                    Exit;
                    //Excp.Reset;
                    //if Excp.Findset then Excp.DeleteAll();
                    //Evaluate(BI,'4664639651950');
                    //Cu1.Get_Shopify_Orders(BI,0);
                    Exit;
                    Pg.LookupMode := True;
                    If Pg.RunModal() = Action::LookupOK then
                    begin
                        Pg.GetRecord(PO);
                        if PO.Get(PO."Document Type"::Order,PO."No.") then
                        begin
                            ven.get(PO."Buy-from Vendor No.");
                            EM := ven."Operations E-Mail";
                            ven."Operations E-Mail" := 'vpacker@practiva.com.au';
                            ven.modify(false);
                            Commit;
                            CU1.Send_PO_Email(PO);
                            ven."Operations E-Mail" := EM;
                            ven.modify(false);
                            Commit;
                        end;
                    end;

                   
                   //
                   //CU1.Send_PO_Email(PO)
                   // Cu.Testrun();
                    //Cu.Testrun2();
                   /* SinvLine.reset;
//                    SinvLine.Setfilter("No.",'<>SHIPPING');
                   // SinvLine[1].Setrange("No.",'SHIPPING');
                    SinvLine.Setrange("Shopify Order No",0);
                    If SinvLine.FindSet() then
                    begin
                        SinvLine.CalcSums("Line Amount");
                        Message('Total = %1',SinvLine."Line Amount");
                   end;
    */
                end;
            }
            action(MSGS6A)
            {
                ApplicationArea = all;
                Caption = 'Set Update Flag';
                trigger OnAction()
                var
                    Item:record Item;
                begin
                    Item.Reset;
                    Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
                    Item.Setfilter("Shopify Product ID",'>0');    
                    Item.Findset;
                    repeat
                        Item."Shopify Update Flag" := true;
                        Item.Modify(false);
                    until Item.next = 0;        
              end;
            }
            action(MSGS7)
            {
                ApplicationArea = all;
                Caption = 'Remove Shopify Duplicates';
                trigger OnAction()
                var
                   Cu:Codeunit "PC Shopify Routines";
                begin
                    if Confirm('Are you absolutely sure you wish to Remove Shopify Duplications now?',False) THen
                        Cu.Remove_Shopify_Duplicates();
                end;
            }
        }
    }
  
}
