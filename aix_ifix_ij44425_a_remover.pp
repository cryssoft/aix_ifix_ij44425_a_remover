#
#  2023/01/12 - cp - This one applies to both AIX and VIOS in our environment,
#		so it's a little more complicated that the first one.
#
#		cp - Fixed some non-variable things from the first class where
#		not everything was based on the $ifixName variable.
#
#  2023/02/17 - cp - Fixed an issue with the hash check of ifixes.
#
#  2023/02/24 - cp - Turned this into a REMOVER for the "a" spins of this
#		ifix, since IBM released "b" spins that won't install over
#		the top of it.
#
#-------------------------------------------------------------------------------
#
#  From Advisory.asc:
#
#-------------------------------------------------------------------------------
#
class aix_ifix_ij44425_a_remover {

    #  This only applies to AIX and VIOS 
    if ($::facts['osfamily'] == 'AIX') {

        #  Set the ifix ID up here to be used later in various names
        $ifixName = 'IJ44425'

        #  Make sure we create/manage the ifix staging directory
        require aix_file_opt_ifixes

        #
        #  For now, we're skipping anything that reads as a VIO server.
        #  We have no matching versions of this ifix / VIOS level installed.
        #
        unless ($::facts['aix_vios']['is_vios']) {

            #
            #  Friggin' IBM...  The ifix ID that we find and capture in the fact has the
            #  suffix allready applied.
            #
            if ($::facts['kernelrelease'] in ['7200-05-03-2148', '7200-05-04-2220']) {
                $ifixSuffix = 'm4a'
                $ifixBuildDate = '221220'
            }
            else {
                if ($::facts['kernelrelease'] == '7200-05-05-2246') {
                    $ifixSuffix = 's5a'
                    $ifixBuildDate = '221220'
                }
                else {
                    $ifixSuffix = 'unknown'
                    $ifixBuildDate = 'unknown'
                }
            }

        }

        #
        #  This one applies equally to AIX and VIOS in our environment, so deal with VIOS as well.
        #
        else {
            if ($::facts['aix_vios']['version'] in ['3.1.3.14', '3.1.3.21']) {
                $ifixSuffix = 'm4a'
                $ifixBuildDate = '221220'
            }
            else {
                if ($::facts['aix_vios']['version'] == '3.1.4.10') {
                    $ifixSuffix = 's5a'
                    $ifixBuildDate = '221220'
                }
                else {
                    $ifixSuffix = 'unknown'
                    $ifixBuildDate = 'unknown'
                }
            }
        }

        #================================================================================
        #  Re-factor this code out of the AIX-only branch, since it applies to both.
        #================================================================================

        #  If we set our $ifixSuffix and $ifixBuildDate, we'll continue
        if (($ifixSuffix != 'unknown') and ($ifixBuildDate != 'unknown')) {

            #  Add the name and suffix to make something we can find in the fact
            $ifixFullName = "${ifixName}${ifixSuffix}"

            #  Only work if this fix is installed
            if ($ifixFullName in $::facts['aix_ifix']['hash'].keys) {
 
                #  Build up the complete name of the ifix staging source and target
                $ifixStagingTarget = "/opt/ifixes/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"

                #  Remove the staged version
                file { "$ifixStagingTarget" :
                    ensure  => "absent",
                    before  => Exec["emgr-remove-${ifixFullName}"],
                }

                #  GAG!  Use an exec resource to install it, since we have no other option yet
                exec { "emgr-remove-${ifixFullName}":
                    path     => '/bin:/sbin:/usr/bin:/usr/sbin:/etc',
                    command  => "/usr/sbin/emgr -r -L $ifixFullName",
                }

                #  Explicitly define the dependency relationships between our resources
                File['/opt/ifixes']->File["$ifixStagingTarget"]->Exec["emgr-install-${ifixName}"]

            }

        }

    }

}
