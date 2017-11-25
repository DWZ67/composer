ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1-unstable.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1-unstable.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data-unstable"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:unstable
docker tag hyperledger/composer-playground:unstable hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� ��Z �=�r��r�=��)'�T��d�fa��^�$ �(��o-�o�%��;�$D�q!E):�O8U���F�!���@^33 I��Dɔh{ͮ�H����\��{�PM����b�;��B���j����pb1�|F�����G|T�b������ǣ� wO����@�G���}=ެ�/�Ȳ5��k�����j
�7 NX��;�e8P3��ހm�9̥�Z6pZ��A����"�������rl�$ !���mp���c �gZ-���:tu�CDg����s���e>u_~�P�5KSB*�������:����ҵ�a(��X˿���G@�wN��W.�S��A�R͞��Ya�9ot���ǟ�:����%���������'?Dj��A��ئk)��O���U�����/�ry�}y�ZJe�p�.Y��?�:=���M�"O����`���'��I埓��X���S�_�t�B���5#��������_�.�r�_,���)�߁J���S�4���#^���c��X�c� .�p� �g7{u2��$��$"(\�'�Tي�u?g�d�2M��cҳ�m
Ϥ]>́�i\��Nv;mt\�����v,���"Lݱ\D�,��5Ǵ�8������p��Z'��NR��ӱ7#��tka�lG��Q9���aR��A�i�mX�)��ǟ�)Ȱi�2��&
	a��j�~ϴT��X
T<ದ�JKiB��ئ��	#�(%���Qsk���!h)M��l�pW�P�|�5��7Y#$��Q��Ө���4	&���h8�ܐ�P�\����n�����IL���8���\.W��n���u=MO�ug�Ν���x|��A��y��ꮡ%�&t@K�u X�mvND�rC3�C�����s�0���S�N!бA��3F��7Ě<���`Y��!i`���	�]\�q�W�a�Qx	"x�FW��Q�W�Rf��\�k���D9��6�Zm@	�P��{Iz1;�@3�k����=�I{�C�}v0b���i��f3�a�p`�#���1i�'�s��S�t�)�i�:�#����S�A�N� ����C��S��1�9�]�;رB��>�(&Wt5�"��&��w���<��btml�#����4�I-������zJ''���F�����>gIe�3�'�7�f�a�	��;N/0މ�r����Z LV���� j�)o�x1B��y��u͋�(k�i���l�0�i�������L�{��%p��ߘ[��/��?_7L���X�S3��ؤ���r�g!��I��>�g�y�t�f��G�1��Y����y6�kY� V��1�>�Ε�>B�0��\�}9U�T�~Ū	��8�W߰+�����E �r��Dm��96r�r��K�?̔ʹ���ˑ��ۼc@��k��Y�6���IM���Y�F��x�-��F�����)O`mu<3K����+r���g����C��;/��6��Ϯ4a��/ym f������%�=_]#	����7`uj�[��ށ�GBm�kY�l�C`���X��G��JOʒ>����C�O2<�.و���m�;9-0
;>�دh���o��X&�S�g5�e�	�+�?$\l�� �o�Q���oa���S��bu�B��TP��6�ra^
s �޸����E��H@���r���%�Q�����Qa)�������ǚ}O�Nh]��u�rLxȠ��/�ιa��OL��q���8��ߋ���O]��f�,�?��cQ��<���_�v��0k���G'��h4�\��↛v�-�ȲLkt,�p��v�f�B]��#��u�x�͵#�R;[��t���y�(���D�l��:���ҾzvIv�H�ݷ�$�sO+��E6��*���nE�P}"�\���13�B&,~g���@�I9�yb�AȪ�?G�à$�
�bl
Q��F{�B*�U�v�@E4�H1UƎ�1B�8x�̙h���c�k�}�k3�P��f,M���V��s)d��'㿣Q�[��E�����W�5��\?DāO�B>:嬂xz-�H�`�?�;Y�t�a.,��W���dt�R���o{G�LWi���"7��m��K!3�����'
���[̖_����-~�����xC/��3k
�a�@rn�G���d�X$�gM�����r�8�f�B�`�B�0X��T��
?��3�(�r�{�9�[�W� �r��M�ꯃ�p�:5��������A�h�߽F䆇`�;QVS��Hȁ��k�;V�^m�3Z��1C"��Trnք]4N��t�٘$��5hc�5&���>��Y�V��^>`�~�d���%�8�1SBo�0~���ށw��>�?����Q8=�/�� x��lF"Ԣn����$����OC�$�}�n�d�]q���i5�0:�펎���^���R1ƌH?�����H��{����.��
D�!�x�Z��2D�����~>s9�9t(��Ў��|���ɥI�>�|�`8>Z���s��\2x�栔;�+�����+�^<��$M]kDH�a����!��Lvsĵ�BDW�_�db�"��6io��Ek��juN�oD���F����$D!�Ȧ҆
9%*r
�7�0Q��&�(J��v�IeJ��pmk���uH!��6
)A��+@2�p	��
��N�v���t�O)M�y�S` ԙ.� �h��Bf�>��C-�<�$�
b[ �M1�w��FZ�_a��gZ��/�*���KOW=~ ɴK=^)%��`]��j����1a�l?����<A���?I���)�������b6�m��M��	�?�b�1{�W��)Dp>cq7��もf���Mʿ�������x�w���4}r?\1;}��4 ��Q>�~�/CZ0��v�K�k�2Jg� ��kF<��AӀߴkj��@`��]�]�}j�k�%����K,����!c}��+ן#�֛�����t� ;0_S|�on��4�G�q��o���||������������٬:� ���N�O��IRt��`��[�=��o���w������������/(Z�Qu�Wx1뵺�l$�z-!�B"�GbLL�QQ�bBJ$�Z|Cj����2���$�"���wr����cl��0+�1E���G߯2L�4l�r4���ǕdV+�(����f�/ߌ��o��fD�e���-{�W���߭0���M��a��9���j�+���#��0!�SB$�4��'p~�?o���y�.��½Sw��Qn��9�Ý���1C�W�_�ⱥ�_\�>;Qv����ӆ�k�:y\9eXga�����\d�|��-#<?��Tv�%g���Q���c�y�npڐ�8���C���\��\6��+�����r���TJVR��Kʍ\I.���a�y_�$����ffZz��j�v͓��)���=�<��)ȭm��f��|��0�9�K�F����Z�fm[oע�\x�9˞�U/O��q���~k(��{,������vE~�a���v�r�qO^7���I��,���l'-C'_���[c�=���T
���+��|%��Wr�I;�i� ��qt���v/U<N�ۙޫ��y���GZ�J�w�BֆG']�-u�+��|���,_xkT���˜􏏤S��pZ;���I�bȽ�Q���#I�}a�˒�����}���Z%y�{2��N�?l��bBnd�S)�{/�#s99��n�%��v�\��{�x�v�{t*9�4R�Ur��k��R�~w��,T˚&��'�N/�Q(�sv^=(�N�L���=�T�{yY�c��UӽL2�+�1�i��<��R>)�72�,�S6i���[�Ԯ�K���Ɠ�d�a��Z����NK@��[\*�k�+i�r7/�Ö�L�\C�g��\1%ڻ��[#�i|�U�����Q"�4N���9	���j�0�M��F�Q�vcf�𪯚Y3Ӂ�\/����������~JLĻj�Z���t�g
�)b�^^^�#��/{���ӌ�阀��k��'^�1[��������3�o��sެ�/>r��Ww�ȣ?uۗ�����G'��<���[�$?t�f�i�c&����k�|����z��P�b��r���䮩EZ�{̜�ˇ\��
�G��ճi���v���6�ɕ���M��j���W[�Y��???�)�|^C�ǌxت��%�/eu$Uw�m��jU�t+��"G�U���ީp������O=f�+�Ն}�^�|`^�/L��u̐^&�� �����/ n�y�$f^/���Ib����y]$f^���Ab����y�#f^�9b��F̵���w�<�?��'-��E�'���ڧn�}��0��[��g!���ɽ\*��e[�L�xǷ�Rrqh�墒.6����L6]�����QÍ�<z����v�1c�gO��V)n��{�-%��)��~ww�u�Nېz����θ�N�hTr0-7����$g���~;�����[�%z��Ǯ������?,�����[4.>���_V'd]%�f���B3OH��A�uh�{�M�;˫k�����`<��?���}/u�j�,�4�k�F#f�:��]�mh��*�G��T�/ ?���K���+x �!P���� @�lC����Z�~�u�l��:�e��+ҋ��t�GCP�����/�z n(+����[ܟ;�?����,&��2��<��m�:y��̝���`���dA�Q8M����d�k��� tF��4�Hp
��tr��M���y�k�y �q ��
z�F=hЇ)���V�>�uO=
>�l�  h hY�O*$��/�Ґ�ig�0J듺mzo�:=�BW}y{2!q <-���݋g�Ҥ�O~�F�u`C����B=���}f��x�OUԟQ^��s�摻��4��ci*��?$8�l��ۗ����{��������yƿ��|y��H�7M�\k����B�����%̐6I���\C	��_�:���!���~���v@�N�~�4q���E��\s��kJp�1�'�R#�V"σQA����=K�#IV3������{�C�.����v;3���ؖ6ә����7].�C)Ng9�t9�N�Ҡ怐va�EZ�\7ܐ�WX�eB�q��7���]�O�tՌ4�����x�{��x�[En�%���%Y�����9�P�����Y��/�&! i��s
���G��T����z�b.}����Ӳ��1Լ�:��Z8d<yk6v�u�~�5]�^z��a�$��*}�ϵ�W�"_�Um������3$�������ə�ρ"��5���	V-@�!oDn�<f'�͜��Tsf*�"�`-.[����t/�l]����C���_���w9�����P���Fu^�L�@�Ens���m��V��N�~�
3�$�[9���c�+���A	Mn���6�-vS��970�ָ�(�?�XRUDa��Э��wk�.�D_��������� ��q���H%����$���J�>�'�����?��i��ӿN��~������?�����������>!����{/���W���yz]C.&�����lR�$\J%�L:�)<���j��ii*��D*G��IiTV%H��K��&�/)����ί��g�o���O���ڏ?���[��������~Ǿ��~��ӛث�Wv�oތ}��],b��F�Go�A~���u��Ъ���~�������o���W]pހ���(�o�e�6�f�{�YΕ4�>i�K0�~:���K�0+xu�]��8�:�"w�=�Q�����ΘS�����%��� �\|Q]Ѥp�]'J8�I o��5�<L(	���.{��]�6E�)��74�s'l����F��<2B��h��Ĺ���қ��@U'
Y�͡[pQ�n���+���0���\lϺd���[�Q�Փn��]�
�ذA�.�f�C{�_���H������(�O���X9��f'�mj]���fio(c�U�P���Sw���4(H�j_(�.����t��`h��zq$�Yt%^�#��"���˺���n�4�[_�t��Hq��Ћ�c�flN/�7�S�t��ʔ;�R�y�?����x�LNS��l�lҼ�_NOf��a����eMj�gT���>I�mUa����L���#SiSii�i��&]g��DN���3��M�F_�ڭ�w���Rj�3*�3*���0_�^n�h2�
�I���x)��X(v�B��͏D��cNVD�Z��f3?^�;�"v��:jq� ��<���B�{mуA�s=ѓuK��n������ȟ�AUO��x��)ϒ�����j�12���VN���[�N���JڤpT��S7:|:UhK�^�5�\�hJ��ĵ�>�H_.~�@�<����,����s)\�rm�:_�H�L�j}�r	%��i79h��犟
]��r5�q�\Z#F)J�ܚʹY�0�v�����N9KP�<OU2��5��!�q�����n�ڵ�R�T��J�a��ͳ�w��v���wc�t���[�{�W��/�{�����������߫��_�F�B�{��/�<��CO��i(������}-v/����~��_��!����/����{)�B؁����-�[���[��&�������W���~�G�c�?�3��RVVYV�Jk��;�yM���t�U.�<J�}�̗��-�,�
d~�ܦ{�-x���\
�<�\�u�fπsa�њ���XW��t�u��6>�v��k��F5�(�]�Ϭ��0.��o$�Uj0+�P����ty��Ե�I˥���@͍�jm��r��g��z�8(i:?�5Ş]g�K�v��Y�
e��'�C�ȺؑH�<.�E2�e�p$,���]�N�t=�0"�i)!�.���0�<#��jd0tB7�v���?��d�h��X��B�th�;\�؆�ԫ%�e8ڠ�#m9�eB�G�C��LjxT��Sr�a��mW���r͜�v���3�)S���ǕRN%^0[������R��CEY�F������!�*.[���l�\�����.���򿲭 V�a� ��� ��XHUL����v��nYe�˪i�<��c�<�����]��rǐ�Bw����0�;�Q��Ǣ[�U9�:Q����\��z�Nv��8����x�Ҫ��ްc4���*��4+��s��^� ���_��Y#2L��t��=�V��!�5Z�]OQ�<E9/д{��	�o��E��B�,�QO�z����f���N��NPt�dڧ���/��3�� 6���فr��k�ޡV.u�b[�p�Vf^Ƙd�wG�iO�J�fS��b*[,��|���W�K��Z�1,�N��ee˫Ɠg҉��R���P�,ׂD��G������"�Tԁ��h%��ޮ ��"��E!�M�G0B�E���L L��|�0��v,&M����y/(��8�h*�ɞ�6[u�Sfg��\N��M�;dv�k�x��V{ℐL:��V�T�j�l���A1i�����eW�)�(�(X Qv�L��O�{L�t�r%�h�c����R��;�ȅ�N���J��
C*F+�z�L5�Ō����飣ܢN�GX�$)��Z{`���ĸ�E�I#����i���`S�R���N�Uc�w1�zir��~�6�D�ү�^��na%2��^'�V��\)ԁ���M�v��w+�|�����\ml�lq9�b��^�^�-�
�<�~��e�2VZ�ث��ן>}J���i<,�m�5TF��ž{{�\{����0%�P=B����	]�(�����K�=0�:m� 4A��Yf8�G�/�q��#�Z�s6ESw��@�FX��^��Vթfۚ�b��}ۧ�U:��x�^���{��w��k��A{"gq5�_�.�����3�Rd����6����Bi��sN��x�w=���(�����oX�^Nmd�!kqE�S�P�Ã,۷S(ɎO��4��.���xخk��2a��{\���}����<��]�����nw��w������zV�F����u�h?Z���_#׬�U�^��yI�a��!g�1�;:���ݰX�����|����R�<����~�8.F-A=�"�2D����d�}�X��ѳ�6E����*)��E�Z���=0�	Tߚ��.��[86ic|�B!/T�t��N�X3S��5 �ࠠa��@ԯμ��gN��������@ӈ%������ �w�>�D�{] �����鍎!�Ƃ���}�#�޹fZd��������:���sh<Y�Ԉ��Y���Ik���(�d�i`ۊX��s"9h~`;ldwB`���f(+�y$��V��h�����f@e\�֋�'�5��a}j�c"��� 
��pMl��:�\N�_�����d����Sa]}�Q��2������}'�ic����6�x�0�(ͯ!�$S˶���bLP؂�����}@�N�6YOå�ƾE�V�2���ő�[�,!��ġ-�h��>~ưyK��-hI	}�ߜ���"_���]*k|;s�Fa$���@?ےW͚"`��8��$k��Ȳu�p݌��4������~v.xf�A�%��T
^_ +���z.������s��Ȧ��P�%���o�k����kJx?o�t�b��c���Zy"��a?]�p��Ȁ�P).úN�,d?Nڛ��A
Գ���2�-���2
��!�@(�x�ؐ(�".xu�6�#ia�f�] �m:C�����#�&-|h�2m���<πl��2KL�7WA��veX
F8�\��:�!�צ�d�a��.�;�x���&@�~ùl\`���#�>l���$������l��MaXN���F ����%:@T@4x@6��U[�G8���P?�g� ��~�efj�x F����Q���}@�$�!V?��T���>�����Qܸ��l�&A[[l� 3�q����s�SD���Q�E�_��9��4UC�P&BS��c��6|���c�q�������sg�[b "�nGH�y;� �C���kGxS���������l��K۸��?�!��?S�t����6�2x?�>�>�A0O+�s��(��������u�f�|�8O��HO��$v��qrG��<��*@��,��E���Y��\������`�6t�u���$U����2)I2�ɑ�D%�$�O�����	5�'$�������}��KK�TV�ȴ#ڢ	�b/��!����By~,7��` �����i��G 9y�®^u;$�0�P[>H"'�iJ�eOe�*���\�I��N�rZϦ�ZR�UBHJ����TF#������?���o���č?R���s�����t=~�����ؿ�h�%��S{��va1(�k_������P�_�jd[k�\`u��rM�r\�+�!Wy�j�L?���*ͲM��z�#�
?�4��ŷN,��'������+8�?�������U��'���J�H�g� C>���U (����X��3	k�$t��%쩒�g0�.�]�M�T� t�e���;�C��hL�F�g<��&v�!����n�h}��n|��0�|�������Z��H^���:�5�}ϗh�����M��.n=��*[��U��ll,��|g��K��t6�u��v?QM��1��O��ej;g6���v��Z� T-�Zb�V-���*'vj���I@F��G���n��w y�����i�t�f`�CbY/�AݖC���,-���䭙2`���k�|�e�1���ꪼO岩�J��ߖP�G��7�O��ik�0��H0�$
:yQ�H���S��� ���lb7�����u�f�ȏ�n��>!�6�ƪ}���y�~�Q2� ;vKk����& ��q�V��	w�#�9n7+������Rb����c��g�:~>�oW�7y��+E��]���H�s����6�y��8	��ޭ�ͧ��gx�u�?I�Sw��K���"�������F�y�wL[��6�.�B�����O�w��Vҗ�������L���F�-��~�%�EO�W6���(��}������[Iwh�<��y�y�h�h�~����������[I���ijN����g�~&��w�\��IJ�TI�e�����x��T�T&)gRYM�U�H��rl�v~�ӗa��Lg���]��[I�o;L�3�����9Q����+�{�����z9���x��+@DEE���&��֙���;{]�R��(f=k���z�Eko�x�&z����^�Ѯ����9�e��<>)����a��=�)~�aJwv���<qctjΉW�l�����9XK����V�h<:,��4&1><M�x+-wh"���Ͽ����h���}�x����u���������M�{�����U�*������_���?�����ѷ���?5��mR���S���v���{��%h �?�����%�������?���?�_���O9���)��P����'E0���@��
�U�pU'\��K�p�����0�Q	����� �������n���"4��a?�4������O�+�k��y���͟��r�,9�i�I��t�r
�~���e�3���e�Ӿ�~"?��y��w�w�~�V?���~E��fVQ����|Y�D�&�33Q��묥�Z�"n��������ya�g�L���X���K�$̅��gNF���G�e�m�,|_����a�?H/���>_�>�����xy�g3%��r����� n�.�)ŜLu�^���z�������.��8�\�yJ��ș��l�}�9��%e�@��Z�Ijg��x����#�����g��9_4u�
b.tn�Y��f4B�A��64@�=-��P�����������,�����ш��A��W���'����z���� �W���8���� �������������������?���	�?��ׇW���k�����3a��Y.,B��$2Nj����v�����u����p'�.�sY�����Ύm)3�8�~N#)ѣ�����F�£ۜ�����;�ذZ�����F.���m��	��3�����lG�a�J�T�#��CA���^y�	�tA(��~%Jf�������K��m|��G��4*&�%�h$�٧Uo��PN��l��g�A4H�@;*��,!��d��G)Qs�'&�����&���tqi>��13���74B�����
4@���K����� ����M����S���+A����q6X��<�|Ns�Oq4F�b!�s>\��1l@�~���$O�X��ߏ&������������ʾ��α��6j0H�f��P���F�[����t��K���qsk{�F˓�,�c��͹H�#.�:�l�w��yh��m��lI���e�˲�b�K����Q'?nGg՛w!���h��������?O��[+�p�C�W��0�S������2��7��	��_}�����0��)��v����тv<��%خ\w�V��Ǘ�O��@K��YϸdL����G��YVH�٥�u����4N�쌭�%)���ز�ɦ`�,NLE�4
�}����h��O��[p����w|o4a�����������?����@ցF�?�����
������"�k��0��$x�q3e�gWb�<�����j��/��K�{;ʐ��Z�� ��7� �z�� W�t�I�*U�v	��w �i�R#G�V?OI�L��[��2l�QQ�j��]Y�<�He@�"c4��TP�-�6z�/�s��W�fV��o7��
$r��n}y	�����+�� 0��X��8�����Vo�0`@xB��ahtNcQ�9���P,7H�r�1�� 3(G�t)z�@0ͥ.���VLܩZ<~Ԅ������i tŔTe�a��k����+�5�i]1�gY�o��Y��cj��}!W!��V:�/�I�I�.5����+��h��䲶{�~!4{Ѡ	���?
�_���?�`£����������?h���*���>�����W�J�2�����;��i����
@�?��C�?��כ����M�D���3���>Fq;��8R���1Ň,�1\Hz��v�GĜ�C�q��BX��04��0��T����x���_w�ץ�s��f��B�>1�Y6
ji��T�:��t�e����t)Ëe��JO�j�Ŏ�.wj#d�!��.��� #��9�L.c*]e���]�q�?9H<��� #7m��}+�p��ԃ����������_%��P�������U������0�W��o��!㽉 �����	�������P9��/�����*����w��
���~�����o�8؎��e���K:e�TY'���wP�2�-����BK�Gf�o�C~d����F�u��(&�d�{Zxܩ]����Α�΢�w�g���i���x�MVt��Kd2�{bw�_O�l2r3O��7���Y�uw���f�|8b\J�t�B[ٶ�����z��s����v#������zGVTE9���B��w+To08`R��c�Gw)�;�OeG��8�jJT��")�޷g!�y%OOxt�u[��ҡ��8Ř?Is4R#�֘tc�.�*;OQ�g�2�ݡ�������pFB�ǲ+C��U����5����7P�n���'p�_kB����MC������ �a��a�����>N��I@#����M���ׇ����Kp��F���	��* ��������[o����7��
|���n����	x�*��{���J��'0��'���@U��x������_?����u�f��p����_;���?@�W��?�C�������~p��T�f�?�CT����{�(���� ����K�p����;��?*B�l����?��k��w����A�k!5�	�����*�?@��?@���A�դ� �F@����_#�����Y��U������*�?@��?@�C���������/�#��P�n����l������J�(�����ф��������?����%�����p�U��o^�<=�P�� ��?��k���|�����$������e���q��sOdx%��{X@RX����>�z�Q���Q���M������	���#u|���OSf/��{�8��@�Vx7o�4#S�~_����� �@c>��$INI[�r��[�	�$��I�L��tg]�=�m�cj#%i�#����9�/t;	ig�%:q$-'['M���	/P�9^�r���M(��T���vw/��7�ah��������?O��[+�p�C�W��0�S������2��7��	��_}����0 u���v�nm�����Pꮆ�rԹ��m|x�/�N�z_�?;\���J��-�8��<N����.1�8�<5
�����Qgv�èS.g�sG���<����ԣ�߮�K�6��{+�q�����oEh��x����Є�/������_���_�������X�����������)����{阔&ҁ�ZS3[�812��\���������M�ɢ+�|��@�-���;;@[�i�����v~�uq
���~��l�,�w�ф�F5тQ����P�9�_��a\�~�쨒l���NZ ��n}y�oO�N����N[,t��Y8�����w�JБW��'t�(�F�4e������r���i2�r��~Y tŔ�.{��=/����өO��\�=�4F6���]X�#���׮&Ģ:��I|���T���:�[s^ �hםҭ�'��b��ٽ���wW��?=��÷G������1��o%���������I���_	�P��ԃ�O��������#^�E������p��
4��	���R��U�����L��*�����[���r�U�5�ϰ%I�_����ic�Ә=�8/��K���:p�/�����,X/��m�4-:ώ�|�U/��y�z�x�������b�!_=?�P�/=�"�ֺ�t1z�.G7���\�RK��ƖLl����Ӫ�_]W]��@��ے�34i�ʘ�*Ȑ֒�F�J[�)�;���F�R���%o���>n0���e�LJ�x��\R�+��0xn�rOVޓ���^ڹ���b4Sn_�0|�������2��.=}&�rdƢ$�Nf�ɖh�e��(�f�;�]�n�B��d�Qz���e��� ���Ĳ[��GT�6��������tʟ��i�P	A�xj�"5c���:ϰ���]dιYb���Tr�]7���@N�������������oE�F��>��Nz>��p������������b��/<�������q/�|���&���������*�Ϝ���h!t���c?�1Dq�����1�}fH��9�t������\��ZA�#Wnj��ߊ�����������_h���Y�^���W	*����������1��4�J���/o�����Ss�4��X������)3_w��gW��E��@�R�O���`C������C~���Y����.:/�����{�����~&�V�K��e����Z�n�W&�3Cjr���7L�g�V���n�-F�6~d�N��]JȸŤ�nڽ(Vw����C�����~����r�ł�贤q�es���5:_�Y�J�A��KAC�~B</�������l�8f�S�ZO�%�h5���)D��V�$;,3��.�m����垶����Qh�ꉅ.*�\��������G�?��[	*8�i�	� d8��G��_�\���0\�>�����νIMmM���)��ԩ3�I�E�fO  x�_��r �(����6݉f���f����JbDP���k��]Z	���/����H���!J�"t��!i|����W|��������R�Y{2a6$Z��}�P'檖?P���+Q��΁������uے��Gm���������?��ǒE��K�,����]�?�_�q�kI�/��I@�A�Q�?��BG��.�A�!-�����*�gI��S�[�?BR�A���cg�e��4v��X��{7�^��~z��A�W.��_��(���e��ʺ9�Q�>�Ը������\��feyl�6�s���ʧ��B�_F�����\a�KW.����5ā��G�]G~]	/�e���Z<-fa���v���U��&'r��5��J�u{f�^�/GNg������P߭��4ꮧe�f�mGisn��´�1�ɶ�l���^&������y�G��qQ�<���N�l8{�>4��iS�-U{{e���h��ق�0l��[eh�ڸ*�Ջw��(s���jƸ�6���T��e0�D���U�/ZJ�ֶӆX=t�}���J�*�U�Z
UGY�2�c���X�8��}�CoJ��W.��ɂ�#n���R!���� ��*�߷�˂���O�HS�a"h��D�=��-B�w*��O��	�?a�'����{���1� 2	��������0�����
�e�L��W������S�A�7���ߠ�;���h�ϫ�>K�k����O���C&������?S"����-BF ��G��7��B�o*����_���������$����O)�R��.z@�A���?uc��?2��Pi�����������P��~Ʉ��o��B�G*���������eB��W�`�GJdA�!#�����?P8�H�� �������i�?�������eB�a�����L��W�����S�?@��� �Ў�ߨ� �?���������}��L�?u����J�l�?L�GE&��������a����	��30����oi�p�������Y��"q���)�	�7� L\/�3Z3��23�*�&eX��*�h�dK&aP�aYzY��Д��q����1x���/O���\��0�?^����2�â\M�\����"��2�ʽU��/���H��2iI�@�c3�im2�N��Ǿ0�|��ht˫�lY��_�v��[a����~õZM�<��A����A)(Lm�Т��k
�L��}��j*�[�zc�iے2���S�8v����%�:*�V���+��<�{W'���g�,��P����p��Y �?��Ȃ���t����>�a �p�dA�!�C�ό�x�n��N��Qa��X���Q�0�QԴ�դ%��PZ��I�����5k��˵n��.���kb�_�Da�����bI�owl�Z4
ۚ5��/ыc(/gۅ:r���}�P��
���l��E��E�����W��!21���_���_���?�����DH&��\��"��4�f��G��z�������k凎,�=�����4�����+��Oe�ӗ�>��~�ن��m�p����C�8��M��n^�mF�>��tw�gK<y��V4�o� �f�)��ʱ%ۈ�u��k]r�Xi3��u�]��~�k��ouvg����W)a�
7{�r��x��l��E����4�h��A5��+ܣ쟓�(6}>v~sCT+�c���|�ϧĞO��#�ө�l}� :�!5�V���Vٟ����2����&�P0E*�A�\|^l��5J��R��;0L�2d\kU�m���%Y���P�����`�GFI�����~5���&��0���Ʉ��7�X��4HM�����mz@�A�Q���_��Ӡ�i�T��$0�����G��č���I���bp�����G��ԍ�0�7���P2}������?�?� �?B�G��x�d��7����r�+@"������X���X�	������_�?R���$�C{��P�Ҿ��͏�M�펙�e\�h�t�?�H�<�D�c�G�X��X���1�#�0���~$��+r�~p��m]�~/����~;E'�U;�����5_�ڦ��`e�M���YyM4[k\�'ռ���S�67NX�xr����i��T�Q<u���b?��{I��n��j�xZ;<W�n`�ya�g�P�7[N���D�m�#N�,O\����9c�l�e��������春�� lm���`�DV����[+:�(�yלS+3?ݻ���P���4V��T���~:2��`���ߋE�Q_�{�������GF����!��J&����p�O��������B�S0�����ypԗ�.�����_&���A��!���
� xk2���d|+��T���/�?��ѦV��\�q��Pm���x�K��K�O��"پtO4�ƺ�2���%M�r ���|�(탭T�}���4r^+)�(0�FU�]��k(ڤI�:[�AS���DT��$����@ҡZd��V����ׇ��s �$	��� `I�� t#.�r�=�����qB���p1��2��l�2?����m����������$��kJ{a�Q@�:��ukLt��>w�0��Ʉ�#n����R����8�+q�@���/�_$n�,���Av��*S��Y�b4C+�4sV�uҢq��t�&-��Ke�&�Xܲh��Y�,�Xr�0������dA�o��	����g���g�lϡܒ^�L=��e��'��v{�x�m��R2'a9Y��?n�d�����k��M�T�w�r���%�Ds�.jZs���̩���i�VC� ��٨Z�FcѲ|���c_t�1���Z���C�Ot m��E�P_�;'�?��Ȅ���d ���E �0���K������g��h���ޖU�0ñJaIi��t{�z(5�Τ��v�����	Gz;�oI��*T��s�UA��zmDc^x�Cz���^%��ٱ�vź�fؒu�rY�[h�6�w\G��\����d�����E'�?��{���� #$� ����_���_���e�x@4d���t�"���F����g�W�3r�m�@���(lq�jJ�_��=� �L��c9 �e!��9 ��촕Ȅ[M�������q��tc9��a�I����-Ec1-��azc�?_[j�<�N�V�^��U�4�7�-~����s��%>�׸��y�y��*�h��A���>�@�:���ح��������J�t�$*�^8�-kS�1�����������(6J?��,�cue8��Fz�T?m[<�E�<I��..�MW��MO6v(�ܹ�`Tr�W��ش��&R�־^�(�6���(��9�'F{�6$չ^�N��l0��DqR��r������sV����6���S���L�I�)���ipn�m���L_�܇�������������m�0'q|W>
��������o�*��u�!����X���	O����*���N���م�.�Wc�{����`��?�Ɇ?ޣ0�\�\]v%�f|�OO�/wj������c���l~z&�7����?�KB�q�C0�����������ϓ$��p��=����]����xp����Y��9��7�?s��aN[��;f�����0����縉�iě���I�|�B���\m���_ɞe_�s���;�7���?~��?b��ۻ����\�O��������zՏ�֠+�������r��.����h?����?�}�wnFr�����+�C����=�^����^�o�ܟ�����0KN4��Khm�\���ʜ٦�;�9�p�{���9��Ż�X��y�q��u�έb%�?]�� ؙ�ϵ�����}�!����{���'���n�����|�{��[��V��}uk|tg-=_O�x>��L#癦�?l|�x�?>}y}�8���&w#��/��X�����r��(̟/^������`Ս�~��+��$>;��oLhuŏmQ�~l��B�))�c{vuI��.H��Lᗟ���ݫ.�"9�������                 ���?`G�j � 