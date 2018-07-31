# LMC Powershell Script Collection
Collection of useful Powershell scripts

- ipv6_cidr_to_mask.ps1

  Useful for turning a list of IPv6 CIDR shorthand into full addresses with mask. Screw your libararies. 

- ntfs_increase_journal_size.ps1

  Script for modifiying the NTFS USN Journaling size so that it's easier to implment via GPO. Useful for security forensics. 
  
- o365_alert_new_inbox_rule.ps1

  Script to be ran every 15 minutes that monitors new Inbox rules that get created in Office 365 that look suspicious. 
  
  
- o365_seek_n_destroy.ps1

  Parse through Office 365 Compliance Center for specific emails and delete them.
