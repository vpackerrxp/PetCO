page 80035 "PC Vendor Stock"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = Item;
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption ='Supplier Stock Levels';
    layout
    {
        area(Content)
        {
            Group(Filters)
            {   
                grid("1")
                {
                    Field("Vendor No.";Ven) 
                    {
                        ApplicationArea = all;
                        TableRelation = Vendor."No." where("No."=filter('SUP-*'));
                        trigger OnValidate()
                        var
                            EDIBuff:Record "PC EDI Header Buffer";
                            instrm:InStream;
                            Payload:text;
                            XmlDoc:XmlDocument;
                            CurrNode:Array[2] of XmlNode;
                            xmlNodeLst:XmlNodeList;
                            CuXML:Codeunit "XML DOM Management";
                            Item:Record Item;
                            i:Integer;
                            win:Dialog;
                            Vend:record Vendor;
                        Begin
                            Vend.get(ven);
                            Name := Vend.Name;
                            If Rec.findset Then rec.DeleteAll();
                            EDIBuff.Reset;
                            EDIBuff.Setrange("Response Type",EDIBuff."Response Type"::Inventory);
                            EDIBuff.setrange("Supplier No.",Ven);
                            If EDIBuff.findset then
                            begin
                                Win.Open('Refreshing Data ...@1@@@@@@@@@@@@@@@@');
                                EDIBuff.Data.CreateInStream(instrm);
                                EDIBuff.CalcFields(Data);
                                Instrm.Read(Payload);
                                XmlDocument.ReadFrom(Payload,Xmldoc);
                                CurrNode[1] := XmlDoc.AsXmlNode();
                                CuXML.FindNode(CurrNode[1],'//InventoryReport/Header/InventoryReportIssueDate',CurrNode[2]);
                                Evaluate(Repdate,CurrNode[2].AsXmlElement().InnerText);
                                CuXML.FindNode(CurrNode[1],'//InventoryReport/InventoryLines',CurrNode[2]);
                                CurrNode[2].SelectNodes('InventoryLine',xmlNodeLst);
                                For i:= 1 to xmlNodeLst.count do
                                begin
                                    Win.update(1,i/10000 DIv 1);
                                    xmlNodeLst.get(i,CurrNode[1]);
                                    CuXML.FindNode(CurrNode[1],'VendorPartNumber',CurrNode[2]);
                                    Item.reset;
                                    Item.Setrange("Vendor Item No.",CurrNode[2].AsXmlElement().InnerText);
                                    If Item.findset then
                                    begin    
                                        If Not rec.get(Item."No.") then
                                        begin
                                            Rec."No." := Item."No.";
                                            Rec.Description := Item.Description;
                                            rec.GTIN := Item.GTIN;
                                            Rec."Vendor Item No." := CurrNode[2].AsXmlElement().InnerText;
                                            CuXML.FindNode(CurrNode[1],'AvailabilityDate',CurrNode[2]);
                                            If Not Evaluate(Rec."Last Counting Period Update"
                                                                ,CurrNode[2].AsXmlElement().InnerText) then
                                                Rec."Last Counting Period Update" := Today;
                                            CuXML.FindNode(CurrNode[1],'QuantityAvailable',CurrNode[2]);
                                            If Not Evaluate(Rec."Unit List Price",CurrNode[2].AsXmlElement().InnerText) then
                                                Clear(Rec."Unit List Price");
                                            Rec.insert(False); 
                                        end;      
                                    end;
                                end;
                                Win.close;
                            end
                            else
                            begin
                                If Rec.findset Then rec.DeleteAll();
                                Clear(Repdate);
                                Message('No Stock Report is available for this Vendor');
                            end;
                            CurrPage.Update(false);
                        End;    
                    }
                    Field("Name";Name)
                    {
                        ApplicationArea = all;
                        Style = Strong;
                        ShowCaption = false;
                        Editable = false;
                    }
                }                   
                Field("Report Date";Repdate)
                {
                   ApplicationArea = all;
                   Editable = false;
                }                   
            }
            repeater(GroupName)
            {
                field(SKU; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(GTIN; Rec.GTIN)
                {
                    ApplicationArea = All;
                }
                field("Supplier Part No"; Rec."Vendor Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Supplier Part No';
                }
                field("Available Qty"; Rec."Unit List Price")
                {
                    ApplicationArea = All;
                    Caption = 'Available Qty';
                    Style = strong;
                }
                field("Availablity Date";Rec."Last Counting Period Update")
                {
                    ApplicationArea = All;
                    Caption = 'Availablity Date';
                }
            }
        }   
    }
  
    Var
        Ven:code[20];
        Repdate:Date;
        Name:Text;
}