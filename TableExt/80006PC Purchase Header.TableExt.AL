tableextension 80006 "PC Purchase Header Ext" extends "Purchase Header"
{
    fields
    {
        modify("Buy-from Vendor No.")
        {
            trigger OnAfterValidate()
            var
                Vend:Record Vendor;
            begin
                if Vend.Get("Buy-from Vendor No.") then "EDI Status" := Vend."EDI Status";
            end;
        }
         field(80000; "Fulfilo ASN Status"; option)
        {
            OptionMembers = " ","Received At Dock",Pending,"In Progress","On Hold",Completed,Cancelled;
        }
        field(80001; "Order Type"; option)
        {
            OptionMembers = Internal,Fulfilo;
            trigger OnValidate()
            var
                Purchline:Record "Purchase Line";
                Flg:Boolean;
                win:Dialog;
                Cu:Codeunit "PC Fulfilio Routines";
            begin
                Purchline.reset;
                Purchline.Setrange("Document Type",Rec."Document Type");
                Purchline.Setrange("Document No.",Rec."No.");
                Purchline.Setrange(Type,Purchline.Type::Item);
                Flg := Rec.Status = Rec.Status::released;
                if Flg then
                begin
                    Rec.Status := Rec.Status::Open;
                end;
                Rec.Modify(false);
                win.Open('Refreshing Lines ....');  
                If "Order Type" = "Order type"::Fulfilo then
                begin
                    If Purchline.Findset then
                    repeat
                        CU.Purch_Rebates(Purchline);
                        Purchline.Modify(true); 
                    until PurchLine.next = 0;
                end
                else 
                begin
                    If Purchline.Findset then
                    repeat
                        Clear(Purchline."Line Rebate %");
                        Clear(Purchline."Indirect Cost %");
                        Purchline.Modify(false); 
                    until PurchLine.next = 0;
                end;
                if Flg then
                begin
                    Rec.Status := Rec.Status::Released;
                    Rec.Modify(false);
                end; 
                win.close;
            end;
        }
        field(80002; "Fulfilo Order ID"; integer)
        {
        }
        field(80003; "Rebate Post Lock"; Boolean)
        {
            Editable = false;
        }
        field(80004; "Requested Receipt Time"; Time)
        {
        }
        field(80005; "EDI Transaction Status"; option)
        {
            OptionMembers = " ",ORIGINAL,REPLACE,CANCEL;
            Editable = false;
        }
        field(80006; "EDI Response Received"; boolean)
        {
            //Editable = False;
        }
        field(80007; "Invoice Disc %"; Decimal)
        {
            Editable = false;
        }
        field(80008; "EDI Dispatch Received"; boolean)
        {
            //Editable = False;
        }
        field(80009; "EDI Invoice Received"; boolean)
        {
            //Editable = False;
        }
        field(80010; "EDI Status"; Option)
        {
            OptionMembers = "Non EDI Vendor","EDI Vendor";
        }

        field(80011; "Fulfilo External Id"; Code[100])
        {
        }
        field(80012; "Fulfilo Identifier"; Code[100])
        {
        }
 
    }
    trigger OnBeforeDelete()
    var 
        Excp:Record "PC Purch Exceptions";
        EDIExcp:Record "PC EDI Exception Messages";
        EDIBuff:record "PC EDI Header Buffer";
    begin
        if Excp.Get(Rec."No.") then Excp.Delete;
        EDIExcp.Reset;
        EDIExcp.Setrange("Purchase Order No.",rec."no.");
        If EDIExcp.FindSet() then EDIExcp.DeleteAll();
        EDIBuff.Reset;
        EDIBuff.Setrange("Purchase Order No.",rec."No.");
        EDIBuff.Setfilter("Response Type",'<>%1',EDIBuff."Response Type"::CreditNote);
    end;
}