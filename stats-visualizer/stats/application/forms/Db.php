<?php

class Application_Form_Db extends Zend_Form
{

    public function init()
    {
        // Set the method for the display form to POST
        $this->setMethod('post');

        // Add a database name element
        $this->addElement('text', 'name', array(
            'label'      => 'Your database name:',
            'required'   => true,
            'value' => 'ldvreports'
//            'filters'    => array('StringTrim'),
//            'validators' => array(
//                'EmailAddress',
//            )
        ));
        
        // Add a database user element
        $this->addElement('text', 'user', array(
            'label'      => 'Your database user:',
            'required'   => true,
            'value' => 'joker'
//            'filters'    => array('StringTrim'),
//            'validators' => array(
//                'EmailAddress',
//            )
        ));
        
        // Add a database host element
        $this->addElement('text', 'host', array(
            'label'      => 'Your database host:',
            'required'   => true,
            'value' => 'localhost'
//            'filters'    => array('StringTrim'),
//            'validators' => array(
//                'EmailAddress',
//            )
        ));        
        
        // Add a database user password element
        $this->addElement('text', 'user password', array(
            'label'      => 'Your database user password:',
//            'required'   => true,
//            'filters'    => array('StringTrim'),
//            'validators' => array(
//                'EmailAddress',
//            )
        ));
        
        // Add the comment element
/*        $this->addElement('textarea', 'comment', array(
            'label'      => 'Please Comment:',
            'required'   => true,
            'validators' => array(
                array('validator' => 'StringLength', 'options' => array(0, 20))
                )
        ));
*/
        // Add a captcha
/*        $this->addElement('captcha', 'captcha', array(
            'label'      => 'Please enter the 5 letters displayed below:',
            'required'   => true,
            'captcha'    => array(
                'captcha' => 'Figlet',
                'wordLen' => 5,
                'timeout' => 300
            )
        ));
*/
        // Add the submit button
        $this->addElement('submit', 'submit', array(
            'ignore'   => true,
            'label'    => 'Sign',
        ));

        // And finally add some CSRF protection
//        $this->addElement('hash', 'csrf', array(
//            'ignore' => true,
//        ));
    }
}
