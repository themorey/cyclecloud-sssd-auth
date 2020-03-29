
SSSD
========

This project uses SSSD to authenticate users against an existing Active Directory domain.  It does not use Kerberos, TLS certs nor RFC2307 Unix Attributes in AD.  A sample template for a Slurm cluster is provided.


## Cluster template file additions:
The following template configs enable a cluster adminstrator to enter in the info needed to populate sssd.conf.

***NOTE:***  *The ldapUser should **NOT** be a domain admin.  A simple ReadOnly user is required.* 


    [[node defaults]]

        [[[configuration adauth]]]
        ldapDomain = $ldapDomain
        ldapUser = $ldapUser
        ldapPassword = $ldapPassword
        ldapUri = $ldapUri
        ldapUriIp = $ldapUriIp
        ldapBackupUri = $ldapBackupUri
        ldapBackupUriIp = $ldapBackupUriIp
        ldapUserSearchBase = $ldapUserSearchBase
        ldapGroupSearchBase = $ldapGroupSearchBase
        ldapAccessFilter = $ldapAccessFilter
        ldapOverrideGid = $ldapOverrideGid
        
        [[[cluster-init sssd:default]]] 
        
        
 *(Add the next section to PARAMETERS section before ADVANCED SETTINGS)*  
 
     [parameters Authentication Settings]
     Order = 15

        [[parameters About Auth]]
        Description = "The cluster will use LDAP for authentication without joining the domain. The following settings add your specific paramaters to the sssd.conf"
        Order = 5

        [[parameters Domain User Settings]]
        Order = 10 

            [[[parameter ldapUser]]]
            Label = LDAP User ID
            Description = User for Authenticating to Domain (ie. cn=user,dc=group,dc=company,dc=com)
            DefaultValue = "cn=user,dc=group,dc=company,dc=com"
            ParameterType = String
            Required = True

            [[[parameter ldapPassword]]]
            Label = LDAP Password
            ParameterType = Password
            Description = User password for Authenticating to Domain
            Required = True

            [[[parameter ldapDomain]]]
            Label = LDAP Domain FQDN
            Description = LDAP Domain (ie. adldap1.testdomain.com)
            DefaultValue = "company.com"
            Required = True	    

        [[parameters sssd.conf Settings]]
        Order = 20

            [[[parameter ldapUri]]]
            Label = LDAP URI
            Description = LDAP URI (ie. ldap1.company.com)
            DefaultValue = ldap1.company.com
            Required = True	 

            [[[parameter ldapUriIp]]]
            Label = LDAP URI IP
            Description = LDAP URI IP (ie. 10.0.0.200)
            Required = True	 

            [[[parameter ldapBackupUri]]]
            Label = LDAP Backup URI
            Description = LDAP Backup URI (ie. ldap2.company.com)
            Required = False	 

            [[[parameter ldapBackupUriIp]]]
            Label = LDAP Backup URI IP
            Description = LDAP Backup URI IP (ie. 10.0.0.201)
            Required = ${ifThenElse(ldapBackupUri !== undefined, True, False)}

            [[[parameter ldapUserSearchBase]]]
            Label = LDAP User Search
            Description = LDAP User Search Base (ie. ou=usr,ou=dept,dc=group,dc=company,dc=com)
            DefaultValue = "ou=usr,ou=dept,dc=group,dc=company,dc=com"
            ParameterType = String
            Required = True	

            [[[parameter ldapGroupSearchBase]]]
            Label = LDAP Group Search
            Description = LDAP Group Search Base (ie. ou=groups,dc=group,dc=company,dc=com)
            ParameterType = String
            DefaultValue = "ou=groups,dc=group,dc=company,dc=com"
            Required = True

            [[[parameter ldapAccessFilter]]]
            Label = LDAP Access Filter
            Description = LDAP Access Filter (ie. memberOf=cn=HPC_Admins_G,ou=HPC,ou=Groups,dc=group,dc=company,dc=com)
            DefaultValue = "memberOf=cn=HPC_Admins_G,ou=HPC,ou=Groups,dc=group,dc=company,dc=com"
            ParameterType = String
            Required = True

            [[[parameter ldapOverrideGid]]]
            Label = LDAP override GID
            Description = LDAP overried GID (ie. 1403160324)
            Required = True
        


## Cluster Specs
This project includes a `sssd.conf` file with default values and a script named `002-sssd.sh`.  The `002-sssd.sh` script does the following:

- Appends *ldapUri* and *ldapUriIp* to `/etc/hosts` to ensure proper name resolution of the AD server
- Installs sssd and dependencies
- Configures sssd, nss and pam
- Copies the default `sssd.conf` from the Spec dir to `/etc/sssd/` and changes permission to 600
- Replaces default values in `sssd.conf` with values from `jetpack config adauth` and starts sssd
- Modifies `sshd_config` to allow password authentication and restarts sshd



## Testing Auth
Cyclecloud managed users still work even with SSSD auth configured.  Login to your cluster node with a Cycle user and test the SSSD auth as follows (where `user1` is an AD user):

    [admin@ip-0A000409 ~]$ id user1
    uid=705601104(user1) gid=705601103(group1) groups=705601103(group1)
    
    [admin@ip-0A000409 ~]$ getent passwd user1
    user1:*:705601104:705601103:user 1:/mnt/exports/shared/home/user1:/bin/bash


You should now be able to SSH with an AD user and submit jobs.
