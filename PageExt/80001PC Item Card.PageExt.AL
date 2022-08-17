pageextension 80001 "PC Item Card Ext" extends "Item Card"
{
    PromotedActionCategoriesML = ENU = 'New,Process,Report,Item,History,Special Sales Prices & Discounts,Approve,Request Approval,Pet Culture',
                                 ENA = 'New,Process,Report,Item,History,Special Sales Prices & Discounts,Approve,Request Approval,Pet Culture';

    layout
    {
        modify("Unit Price")
        {
            ApplicationArea = All;
            Caption = 'RRPrice';
        }
    
        addafter(Description)
        {
            field("Product Code"; rec."Product Code")
            {
                ApplicationArea = All;
            }
        }
        addafter("Item Category Code")
        {
            field("Brand"; rec."Brand")
            {
                ApplicationArea = All;
            }
        }
        addafter(Item)
        {
            Group("Pet Culture")
            {
                field("Item Type";rec."Shopify Item")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    var
                        Rel:Array[2] of Record "PC Shopify Item Relations";
                        pg:page "PC Shopify Item Relations";
                        item:Record item;
                        title:text;
                        Cnt:Integer;
                        TestNo:text;
                    begin
                        If rec."Shopify Item" = rec."Shopify Item"::Shopify then
                        begin 
                            testNo := Rec."No.";    
                            if (rec.Type = rec.Type::"Non-Inventory") And testno.StartsWith('PAR-')  then
                            begin
                                    Rel[1].reset;
                                    rel[1].SetCurrentKey("Parent Item No.");
                                    rel[1].Setrange("Parent Item No.",rec."No.");
                                    If rel[1].count = 0 then
                                    begin
                                        pG.SetParent(rec."No."); 
                                        pG.RunModal();
                                        iF rel[1].count = 0 then Message('Parent Items Should have child items defined.');
                                    end
                                    else
                                    begin
                                        Clear(Cnt);    
                                        Rel[1].findset;
                                        Rel[1].Setrange("Un Publish Child",false);
                                        repeat
                                            Item.Get(Rel[1]."Child Item No.");
                                            title := Item."Shopify Body Html";
                                            Rel[2].reset;
                                            Rel[2].Setrange("Parent Item No.",rec."No.");
                                            Rel[2].Setfilter("Child Item No.",'<>%1',Item."No.");
                                            Rel[2].Setrange("Un Publish Child",false);
                                            if Rel[2].Findset then
                                            repeat
                                                Item.Get(Rel[2]."Child Item No.");
                                                If title = Item."Shopify Body Html" then Cnt+=1;
                                            until (Rel[2].next = 0) or (Cnt>0);
                                        until Rel[1].next = 0;
                                        If Cnt > 0 then
                                        begin 
                                            Clear(rec."Shopify Item");
                                            If Confirm('Parent Contains Child Items With Identical Selling Option\'
                                                     + 'Review The Parent Child Relations Now?',True) then
                                            begin
                                                pG.SetParent(rec."No."); 
                                                pG.RunModal();
                                            end;
                                            Message('The Shopify Type Has Been Reset To Respect The Error')
                                        end;     
                                    end; 
                            end;
                        end;
                        CurrPage.update(true);    
                    end;
                 }
                field("Shopify Title"; rec."Shopify Title")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
                field("Shopify Body Html"; rec."Shopify Body Html")
                {
                    ApplicationArea = All;
                    Caption = 'Shopify Selling Option';
                }
                field("Category Name"; rec."Catergory Name")
                {
                    ApplicationArea = All;
                    Caption = 'Category Name';
                }
                field("Sub Category Name"; rec."Sub Catergory Name")
                {
                    ApplicationArea = All;
                    Caption = 'Sub Categfory Name';
                }
                field("Shopify CRM Transfer Flag"; rec."Shopify Transfer Flag")
                {
                    ApplicationArea = All;
                }
                field("Key Info Flag"; rec."Key Info Changed Flag")
                {
                    ApplicationArea = All;
                }
                field("Auto Delivery"; rec."Auto Delivery")
                {
                    ApplicationArea = All;
                }
                 field("Is In Shopify"; rec."Is In Shopify Flag")
                {
                    ApplicationArea = All;
                    Caption = 'Is In Shopify';
                    Editable = Flg4;
                }
                Group("Actions")
                {
                    field("A";'Remove Shopify Item')
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Style = Strong;
                        Enabled = Flg1;
                        trigger OnDrillDown()
                        var
                            Item:Record Item;
                            Cu:Codeunit "PC Shopify Routines";
                        begin
                            if Confirm('Are You Absolutely Sure You Wish Remove Product From Shopify Now?',False) then
                                If Cu.Delete_Items(rec."No.") then
                                begin
                                    rec.Get(rec."No.");
                                    Clear(rec."Shopify Item");
                                    rec.Modify(False); 
                                    Message('Product has been removed from Shopify');
                                end
                                else 
                                    Message('Delete Failed');    
                            CurrPage.update(false);
                        end;
                    }
                    grid("GRD1")
                    {
                        field("B";'Parent Item Management')
                        {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Style = Strong;
                        Enabled = flg2;
                        trigger OnDrillDown()
                            var
                                Rel:Record "PC Shopify Item Relations";
                                pg:Page "PC Shopify Item Relations";
                            begin
                                pg.SetParent(Rec."No.");
                                Pg.RunModal();
                            end;
                        }
                        Field("Child Count";Get_Child_Count())
                        {
                            ApplicationArea = All;
                            Style = Strong;
                       }
                    }
                   field("C";'Shopify Pricing')
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Style = Strong;
                        enabled = flg3;
                        trigger OnDrillDown()
                        var
                            Rel:Record "PC Shopify Item Relations";
                            pg:Page "PC Shopify Pricing";
                        begin
                            pg.Set_item(rec."No.");
                            Pg.RunModal();
                        end;
                    }
                    field("D";'Update Shopify Item')
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Style = Strong;
                        //enabled = flg2;
                        trigger OnDrillDown()
                        var
                            Cu:Codeunit "PC Shopify Routines";
                            rel:record "PC Shopify Item Relations";
                        begin
                            //see if this is a parent Item 
                            Rel.Reset;
                            Rel.SetRange("Parent Item No.",rec."No.");
                            If Rel.findset then
                            begin
                                // check that the parent has children
                                If Rel.count > 0 then
                                begin
                                    Rec."Shopify Update Flag" := True;
                                    Rec.Modify(false);    
                                    Cu.Process_Shopify_Items(Rec."No.");
                                end;    
                            end        
                            else
                            begin
                                // now check that this is a standalone ie Not a Child any more
                                Rel.Setrange("Parent Item No.");
                                Rel.Setrange("Child Item No.",rec."No.");
                                If Not Rel.findset then Cu.Process_Shopify_Items(Rec."No.")    
                            end;        
                            Currpage.Update(False);
                        end;
                    }
                }    
                Group("Shopify Reference Information")
                { 
                    field("Shopify Product ID"; rec."Shopify Product ID")
                    {
                        ApplicationArea = All;
                        Editable = Flg4;
                        trigger OnDrillDown()
                        var 
                            CU:Codeunit "PC Shopify Routines";
                            ItemTxt:Text;
                            i:Integer;
                        begin
                            ItemTxt := Rec."No.";
                            If (Rec."Shopify Product ID" > 0) and Itemtxt.StartsWith('PAR-') then
                                  Message(Cu.Check_Product_ID(rec,i));
 
                        end;    
                    }
                    field("Shopify Product Variant ID"; rec."Shopify Product Variant ID")
                    {
                        ApplicationArea = All;
                        Editable = Flg4;
                    }
                    field("Shopify Product Inventory ID"; rec."Shopify Product Inventory ID")
                    {
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field("Shopify Location Inventory ID"; rec."Shopify Location Inventory ID")
                    {
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field("CRM Shopify Product ID"; rec."CRM Shopify Product ID")
                    {
                        ApplicationArea = All;
                        Editable = Flg4;
                    }
                    field("Associated Parent"; Get_Parent)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        trigger OnDrillDown()
                        var
                            Pg:page "Item Card";
                            Item:Record Item;
                        begin
                            If Item.Get(Get_Parent()) then
                            begin
                                Pg.SetRecord(Item);
                                Pg.RunModal();
                            end;    
                        end;    
                    }
                }     
            }
        } 
    }
    actions
    {
        addafter(Attributes)
        {
            Group("PET")
            {
                Caption = 'Pet Culture';
                action(Msg1)
                {
                    ApplicationArea = all;
                    Caption = 'Synchronise Shopify Item';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category9;
                    ToolTip = 'Updates Shopify Item.';
                    trigger OnAction()
                    var
                        cu:Codeunit "PC Shopify Routines";
                        Rel:Record "PC Shopify Item Relations";
                        Flg:Boolean; 
                    begin
                        Flg := false;
                        If (rec.Type = rec.Type::"Non-Inventory") ANd (rec."Shopify Item" = rec."Shopify Item"::Shopify) then
                        begin
                            Rel.Reset;
                            Rel.SetRange("Parent Item No.",rec."No.");
                            Flg := Rel.count > 0;
                        end;
                        If (rec.Type = rec.Type::Inventory) ANd (rec."Shopify Item" = rec."Shopify Item"::Shopify) then
                        begin
                            Rel.Reset;
                            Rel.SetRange("Child Item No.",rec."No.");
                            Flg := Not Rel.FindSet();
                        end;
                        If Flg then
                        begin 
                            If Confirm('Synchronise Item with Shopify Now?',True) then
                                cu.Process_Shopify_Items(rec."No.");
                        end         
                        else
                            Message('Only valid for shopify parents/stand alone items');
                    end;
                } 
                action(Msg2)
                {
                    ApplicationArea = All;
                    Caption = 'Access Shopify ID';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category9;
                    trigger OnAction()
                    begin
                        Case StrMenu('Enabled Access,Disable Access',1) of
                            1:Flg4 := true;
                            2:Clear(Flg4);
                        end;
                        CurrPage.Update(false);
                    end;
                }
                action(Msg3)
                {
                    ApplicationArea = All;
                    Caption = 'Publish/Unpublish Item';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category9;
                    trigger OnAction()
                    var
                        Cu:Codeunit "PC Shopify Routines";
                    begin
                        If Rec."Shopify Product ID" > 0 then
                            Case Strmenu('Publish Item,UnPublish Item') of
                                0:Exit;
                                1:Cu.Publish_UnPblish_Shopify_Items(Rec."No.",True);
                                2:Cu.Publish_UnPblish_Shopify_Items(Rec."No.",False);
                            end;    
                    end;
                }
            }   
        }
    }
    trigger OnOpenPage()
    Begin
        SetFlags();
    End;
    procedure SetFlags()
    begin
        Flg1 := (rec."Shopify Item" = rec."Shopify Item"::Shopify) And (rec."Shopify Product ID" > 0);
        Flg2 := (rec."Shopify Item" = rec."Shopify Item"::Shopify) And (rec.Type =rec.type::"Non-Inventory");
        Flg3 := (rec."Shopify Item" = rec."Shopify Item"::Shopify) And (rec.Type = rec.type::Inventory);
        Flg4 := false;
    end;
    local Procedure Get_Parent():Code[20]
    var
        Rel:Record "PC Shopify Item Relations";
    begin
        Rel.Reset;
        Rel.Setrange("Child Item No.",Rec."No.");
        If Rel.findset then exit(Rel."Parent Item No.");
        Exit('N/A');
    end; 
    local procedure Get_Child_Count():Integer
    var
        Rel:Record "PC Shopify Item Relations";
    begin
        Rel.Reset;
        Rel.Setrange("Parent Item No.",Rec."No.");
        Rel.Setrange("Un Publish Child",false);
        If Rel.findset then 
            exit(Rel.Count)
        else
            Exit(0);    
    end; 
    var
        Flg1:Boolean;    
        Flg2:Boolean;    
        Flg3:Boolean;
        Flg4:boolean;

}