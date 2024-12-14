-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 14, 2024 at 04:18 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `railway_management_system`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `Add_Maintenance` (IN `p_Train_ID` INT, IN `p_Start_Date` DATE, IN `p_End_Date` DATE, IN `p_Description` TEXT)   BEGIN
    -- Insert maintenance record
    INSERT INTO Maintenance (Train_ID, Start_Date, End_Date, Description) 
    VALUES (p_Train_ID, p_Start_Date, p_End_Date, p_Description);
    
    -- Update train status to "Maintenance"
    UPDATE Trains SET Status = 'Maintenance' WHERE Train_ID = p_Train_ID;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Book_Ticket` (IN `p_User_ID` INT, IN `p_Train_ID` INT, IN `p_Seat_Number` VARCHAR(10), IN `p_Journey_Date` DATE, OUT `p_Ticket_ID` INT, OUT `p_Status` VARCHAR(50))   BEGIN
    DECLARE v_Train_Capacity INT;
    DECLARE v_Booked_Seats INT;
    
    -- Check train capacity
    SELECT Capacity INTO v_Train_Capacity FROM Trains WHERE Train_ID = p_Train_ID;
    
    -- Check for already booked seats
    SELECT COUNT(*) INTO v_Booked_Seats FROM Tickets WHERE Train_ID = p_Train_ID AND Journey_Date = p_Journey_Date;
    
    -- If there is space, proceed with booking
    IF v_Booked_Seats < v_Train_Capacity THEN
        -- Insert Booking record
        INSERT INTO Bookings (User_ID, Train_ID, Booking_Date, Payment_Status) 
        VALUES (p_User_ID, p_Train_ID, CURDATE(), 'Pending');
        
        -- Get the last inserted Booking ID
        SET p_Ticket_ID = LAST_INSERT_ID();
        
        -- Insert Ticket record
        INSERT INTO Tickets (Booking_ID, Seat_Number, Price, Journey_Date) 
        VALUES (p_Ticket_ID, p_Seat_Number, (SELECT Fare FROM Fares WHERE Train_ID = p_Train_ID AND Route_ID = (SELECT Route_ID FROM Schedules WHERE Train_ID = p_Train_ID LIMIT 1) LIMIT 1), p_Journey_Date);
        
        SET p_Status = 'Ticket Booked Successfully';
    ELSE
        SET p_Status = 'No Available Seats';
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Cancel_Booking` (IN `p_Booking_ID` INT, OUT `p_Status` VARCHAR(50))   BEGIN
    DECLARE v_Train_ID INT;
    
    -- Get the Train_ID associated with the booking
    SELECT Train_ID INTO v_Train_ID FROM Bookings WHERE Booking_ID = p_Booking_ID;
    
    -- Delete ticket(s) related to the booking
    DELETE FROM Tickets WHERE Booking_ID = p_Booking_ID;
    
    -- Delete the booking record
    DELETE FROM Bookings WHERE Booking_ID = p_Booking_ID;
    
    -- Update Train status if the booking is cancelled
    UPDATE Trains SET Status = 'Running' WHERE Train_ID = v_Train_ID;
    
    SET p_Status = 'Booking Cancelled Successfully';
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Generate_Payment` (IN `p_Booking_ID` INT, IN `p_Payment_Mode` ENUM('Cash','Online'), OUT `p_Payment_Status` VARCHAR(50))   BEGIN
    DECLARE v_Amount DECIMAL(10, 2);
    
    -- Fetch fare for the booking
    SELECT Price INTO v_Amount 
    FROM Tickets WHERE Booking_ID = p_Booking_ID LIMIT 1;
    
    -- Insert Payment record
    INSERT INTO Payment (Booking_ID, Payment_Mode, Payment_Date, Amount) 
    VALUES (p_Booking_ID, p_Payment_Mode, CURDATE(), v_Amount);
    
    -- Update Payment Status in Bookings Table
    UPDATE Bookings SET Payment_Status = 'Completed' WHERE Booking_ID = p_Booking_ID;
    
    SET p_Payment_Status = 'Payment Completed Successfully';
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Update_Schedule` (IN `p_Schedule_ID` INT, IN `p_Departure_Time` DATETIME, IN `p_Arrival_Time` DATETIME)   BEGIN
    -- Update the schedule for a specific train
    UPDATE Schedules
    SET Departure_Time = p_Departure_Time, Arrival_Time = p_Arrival_Time
    WHERE Schedule_ID = p_Schedule_ID;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Update_User_Info` (IN `p_User_ID` INT, IN `p_New_Address` VARCHAR(255), IN `p_New_Phone_Number` VARCHAR(15), OUT `p_Status` VARCHAR(50))   BEGIN
    -- Update the user information
    UPDATE Users 
    SET Address = p_New_Address, Phone_Number = p_New_Phone_Number 
    WHERE User_ID = p_User_ID;
    
    IF ROW_COUNT() > 0 THEN
        SET p_Status = 'User Information Updated Successfully';
    ELSE
        SET p_Status = 'User Not Found';
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `Booking_ID` int(11) NOT NULL,
  `User_ID` int(11) NOT NULL,
  `Train_ID` int(11) NOT NULL,
  `Booking_Date` date NOT NULL,
  `Payment_Status` enum('Pending','Completed') DEFAULT 'Pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`Booking_ID`, `User_ID`, `Train_ID`, `Booking_Date`, `Payment_Status`) VALUES
(1, 1, 1, '2024-12-01', 'Completed'),
(2, 2, 2, '2024-12-02', 'Pending'),
(3, 3, 3, '2024-12-03', 'Completed'),
(4, 4, 4, '2024-12-04', 'Pending'),
(5, 5, 5, '2024-12-05', 'Completed'),
(6, 6, 6, '2024-12-06', 'Completed'),
(7, 7, 7, '2024-12-07', 'Pending'),
(8, 8, 8, '2024-12-08', 'Completed'),
(9, 9, 9, '2024-12-09', 'Pending'),
(10, 10, 10, '2024-12-10', 'Completed');

--
-- Triggers `bookings`
--
DELIMITER $$
CREATE TRIGGER `Log_Booking_Payment_Status_Modification` AFTER UPDATE ON `bookings` FOR EACH ROW BEGIN
    -- Only log if the Payment_Status has changed
    IF OLD.Payment_Status <> NEW.Payment_Status THEN
        INSERT INTO Booking_Audit (Booking_ID, Old_Payment_Status, New_Payment_Status, Change_Timestamp, Changed_By)
        VALUES (NEW.Booking_ID, OLD.Payment_Status, NEW.Payment_Status, CURRENT_TIMESTAMP, NEW.User_ID);
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Log_User_Action` AFTER INSERT ON `bookings` FOR EACH ROW BEGIN
    INSERT INTO User_Audit (User_ID, Action_Type, Action_Description)
    VALUES (NEW.User_ID, 'Booking', CONCAT('Booking created for Train_ID ', NEW.Train_ID, ' on ', NEW.Booking_Date));
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `booking_audit`
--

CREATE TABLE `booking_audit` (
  `Audit_ID` int(11) NOT NULL,
  `Booking_ID` int(11) NOT NULL,
  `Old_Booking_Status` enum('Pending','Completed','Cancelled') NOT NULL,
  `New_Booking_Status` enum('Pending','Completed','Cancelled') NOT NULL,
  `Change_Timestamp` datetime DEFAULT current_timestamp(),
  `Changed_By` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `booking_details`
-- (See below for the actual view)
--
CREATE TABLE `booking_details` (
`Booking_ID` int(11)
,`User_Name` varchar(100)
,`Train_Name` varchar(100)
,`Booking_Date` date
,`Payment_Status` enum('Pending','Completed')
);

-- --------------------------------------------------------

--
-- Table structure for table `complaints`
--

CREATE TABLE `complaints` (
  `Complaint_ID` int(11) NOT NULL,
  `User_ID` int(11) NOT NULL,
  `Complaint_Text` text NOT NULL,
  `Status` enum('Pending','Resolved') DEFAULT 'Pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `complaints`
--

INSERT INTO `complaints` (`Complaint_ID`, `User_ID`, `Complaint_Text`, `Status`) VALUES
(1, 1, 'The air conditioning in the train was not working properly.', 'Pending'),
(2, 2, 'The train was delayed by more than 2 hours without any notification.', 'Resolved'),
(3, 3, 'The seats were uncomfortable, and there was no proper cleanliness in the coach.', 'Pending'),
(4, 4, 'The ticket booking system was not accepting my payment despite multiple attempts.', 'Resolved'),
(5, 5, 'The train was overcrowded, and there was no space to sit for many passengers.', 'Pending'),
(6, 6, 'The restrooms were in a very unhygienic condition throughout the journey.', 'Resolved'),
(7, 7, 'There was a lack of proper announcements during the journey.', 'Pending'),
(8, 8, 'The train’s Wi-Fi was not working even though it was advertised.', 'Resolved'),
(9, 9, 'The food served on the train was cold and tasteless.', 'Pending'),
(10, 10, 'The train was delayed but no information was provided at the station.', 'Resolved');

-- --------------------------------------------------------

--
-- Table structure for table `employees`
--

CREATE TABLE `employees` (
  `Employee_ID` int(11) NOT NULL,
  `Name` varchar(100) NOT NULL,
  `Role` varchar(50) NOT NULL,
  `Phone_Number` varchar(15) DEFAULT NULL,
  `Email` varchar(100) DEFAULT NULL,
  `Address` text NOT NULL,
  `Salary` decimal(10,2) NOT NULL,
  `Join_Date` date NOT NULL,
  `Shift` enum('Morning','Evening','Night') NOT NULL,
  `Station_Assigned` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `employees`
--

INSERT INTO `employees` (`Employee_ID`, `Name`, `Role`, `Phone_Number`, `Email`, `Address`, `Salary`, `Join_Date`, `Shift`, `Station_Assigned`) VALUES
(11, 'Jamal Uddin', 'Station Manager', '01761000001', 'jamal.manager@gmail.com', 'Dhaka', 50000.00, '2015-06-01', 'Morning', 1),
(12, 'Aminul Islam', 'Ticket Checker', '01761000002', 'aminul.tickets@gmail.com', 'Chattogram', 25000.00, '2017-03-15', 'Evening', 2),
(13, 'Shakil Hossain', 'Train Driver', '01761000003', 'shakil.driver@gmail.com', 'Sylhet', 40000.00, '2018-11-10', 'Night', 3),
(14, 'Mahmuda Begum', 'Customer Service', '01761000004', 'mahmuda.service@gmail.com', 'Khulna', 30000.00, '2016-07-20', 'Morning', 4),
(15, 'Mizanur Rahman', 'Ticket Seller', '01761000005', 'mizan.tickets@gmail.com', 'Rajshahi', 20000.00, '2019-01-05', 'Evening', 5),
(16, 'Rubel Mia', 'Maintenance Staff', '01761000006', 'rubel.maintenance@gmail.com', 'Barishal', 15000.00, '2020-08-15', 'Night', 6),
(17, 'Tahmina Sultana', 'Security Guard', '01761000007', 'tahmina.security@gmail.com', 'Gazipur', 18000.00, '2014-04-25', 'Morning', 7),
(18, 'Nafis Ahmed', 'Station Manager', '01761000008', 'nafis.manager@gmail.com', 'Cumilla', 52000.00, '2013-12-01', 'Morning', 8),
(19, 'Anisur Rahman', 'Train Conductor', '01761000009', 'anisur.conductor@gmail.com', 'Mymensingh', 35000.00, '2018-09-18', 'Night', 9),
(20, 'Sadia Jahan', 'Admin Staff', '01761000010', 'sadia.admin@gmail.com', 'Rangpur', 28000.00, '2019-11-11', 'Evening', 10);

-- --------------------------------------------------------

--
-- Table structure for table `fares`
--

CREATE TABLE `fares` (
  `Fare_ID` int(11) NOT NULL,
  `Train_ID` int(11) NOT NULL,
  `Route_ID` int(11) NOT NULL,
  `Class_ID` int(11) NOT NULL,
  `Fare` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `fares`
--

INSERT INTO `fares` (`Fare_ID`, `Train_ID`, `Route_ID`, `Class_ID`, `Fare`) VALUES
(1, 1, 1, 1, 1500.00),
(2, 2, 2, 2, 1200.00),
(3, 3, 3, 3, 800.00),
(4, 4, 4, 1, 1800.00),
(5, 5, 5, 2, 1300.00),
(6, 6, 6, 3, 700.00),
(7, 7, 7, 1, 1600.00),
(8, 8, 8, 2, 1400.00),
(9, 9, 9, 3, 750.00),
(10, 10, 10, 1, 1700.00);

-- --------------------------------------------------------

--
-- Table structure for table `feedback`
--

CREATE TABLE `feedback` (
  `Feedback_ID` int(11) NOT NULL,
  `User_ID` int(11) NOT NULL,
  `Feedback_Text` text NOT NULL,
  `Rating` int(11) DEFAULT NULL CHECK (`Rating` between 1 and 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `feedback`
--

INSERT INTO `feedback` (`Feedback_ID`, `User_ID`, `Feedback_Text`, `Rating`) VALUES
(1, 1, 'Great service and punctuality. I am satisfied with my experience.', 5),
(2, 2, 'Comfortable train, but the journey was delayed by 30 minutes.', 3),
(3, 3, 'The staff was helpful, but the train was overcrowded.', 4),
(4, 4, 'Very clean and fast service, enjoyed the trip!', 5),
(5, 5, 'The booking process was smooth, but there was no food service on board.', 4),
(6, 6, 'Poor condition of the train. It was not as expected.', 2),
(7, 7, 'Good experience overall, but the seats could be more comfortable.', 3),
(8, 8, 'The train was late, but the rest of the service was fine.', 3),
(9, 9, 'The journey was smooth, and I enjoyed the amenities provided.', 4),
(10, 10, 'Had a great trip! The train was on time and clean.', 5);

--
-- Triggers `feedback`
--
DELIMITER $$
CREATE TRIGGER `Update_User_Rating_After_Feedback` AFTER INSERT ON `feedback` FOR EACH ROW BEGIN
    DECLARE v_Avg_Rating DECIMAL(3, 2);
    
    -- Calculate the average rating for the user
    SELECT AVG(Rating) INTO v_Avg_Rating
    FROM Feedback
    WHERE User_ID = NEW.User_ID;
    
    -- Update the user's average rating
    UPDATE Users
    SET Rating = v_Avg_Rating
    WHERE User_ID = NEW.User_ID;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `feedback_summary`
-- (See below for the actual view)
--
CREATE TABLE `feedback_summary` (
`Feedback_ID` int(11)
,`User_Name` varchar(100)
,`Feedback_Text` text
,`Rating` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `luggage`
--

CREATE TABLE `luggage` (
  `Luggage_ID` int(11) NOT NULL,
  `Booking_ID` int(11) NOT NULL,
  `Weight` decimal(10,2) NOT NULL,
  `Extra_Charge` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `luggage`
--

INSERT INTO `luggage` (`Luggage_ID`, `Booking_ID`, `Weight`, `Extra_Charge`) VALUES
(1, 1, 20.00, 100.00),
(2, 2, 15.50, 50.00),
(3, 3, 25.00, 150.00),
(4, 4, 18.00, 75.00),
(5, 5, 30.00, 200.00),
(6, 6, 10.00, NULL),
(7, 7, 22.50, 120.00),
(8, 8, 17.00, 60.00),
(9, 9, 28.00, 180.00),
(10, 10, 12.00, NULL);

--
-- Triggers `luggage`
--
DELIMITER $$
CREATE TRIGGER `Add_Extra_Charge_For_Overweight_Luggage` AFTER INSERT ON `luggage` FOR EACH ROW BEGIN
    DECLARE v_Max_Weight DECIMAL(10, 2) DEFAULT 20.00; -- Maximum allowed weight (in kg)
    DECLARE v_Extra_Charge DECIMAL(10, 2);
    
    -- Check if the luggage exceeds the allowed weight
    IF NEW.Weight > v_Max_Weight THEN
        -- Calculate the extra charge (charge for every kg over the limit)
        SET v_Extra_Charge = (NEW.Weight - v_Max_Weight) * 10; -- Charge rate per kg
        -- Update the luggage record with the extra charge
        UPDATE Luggage 
        SET Extra_Charge = v_Extra_Charge
        WHERE Luggage_ID = NEW.Luggage_ID;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `luggage_details`
-- (See below for the actual view)
--
CREATE TABLE `luggage_details` (
`Luggage_ID` int(11)
,`Weight` decimal(10,2)
,`Extra_Charge` decimal(10,2)
,`Booking_ID` int(11)
,`User_ID` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `maintenance`
--

CREATE TABLE `maintenance` (
  `Maintenance_ID` int(11) NOT NULL,
  `Train_ID` int(11) NOT NULL,
  `Start_Date` date NOT NULL,
  `End_Date` date DEFAULT NULL,
  `Description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `maintenance`
--

INSERT INTO `maintenance` (`Maintenance_ID`, `Train_ID`, `Start_Date`, `End_Date`, `Description`) VALUES
(1, 1, '2024-12-01', '2024-12-03', 'Routine checkup and engine servicing.'),
(2, 2, '2024-12-02', '2024-12-04', 'Repair of damaged seating and minor electrical work.'),
(3, 3, '2024-12-05', '2024-12-06', 'Cleaning and inspection of air conditioning system.'),
(4, 4, '2024-12-07', '2024-12-09', 'Overhaul of wheels and axles, plus safety checks.'),
(5, 5, '2024-12-10', '2024-12-12', 'Full engine inspection and air brake maintenance.'),
(6, 6, '2024-12-13', '2024-12-15', 'Replacement of seats and carpet cleaning.'),
(7, 7, '2024-12-16', '2024-12-17', 'Maintenance of electrical systems and control panels.'),
(8, 8, '2024-12-18', '2024-12-19', 'Replacement of door handles and window seals.'),
(9, 9, '2024-12-20', '2024-12-22', 'Cleaning of train tracks and minor engine adjustments.'),
(10, 10, '2024-12-23', '2024-12-25', 'Servicing of the air conditioning and heating systems.');

--
-- Triggers `maintenance`
--
DELIMITER $$
CREATE TRIGGER `Update_Train_Status_After_Maintenance` AFTER UPDATE ON `maintenance` FOR EACH ROW BEGIN
    -- If the maintenance end date is provided and the maintenance period is over, update the train status to 'Running'
    IF NEW.End_Date <= CURDATE() THEN
        UPDATE Trains SET Status = 'Running' WHERE Train_ID = NEW.Train_ID;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `payment`
--

CREATE TABLE `payment` (
  `Payment_ID` int(11) NOT NULL,
  `Booking_ID` int(11) NOT NULL,
  `Payment_Mode` enum('Cash','Online') NOT NULL,
  `Payment_Date` date NOT NULL,
  `Amount` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payment`
--

INSERT INTO `payment` (`Payment_ID`, `Booking_ID`, `Payment_Mode`, `Payment_Date`, `Amount`) VALUES
(1, 1, 'Cash', '2024-12-01', 1500.00),
(2, 2, 'Online', '2024-12-02', 1200.00),
(3, 3, 'Cash', '2024-12-03', 1300.00),
(4, 4, 'Online', '2024-12-04', 1100.00),
(5, 5, 'Cash', '2024-12-05', 1400.00),
(6, 6, 'Online', '2024-12-06', 1600.00),
(7, 7, 'Cash', '2024-12-07', 1250.00),
(8, 8, 'Online', '2024-12-08', 1350.00),
(9, 9, 'Cash', '2024-12-09', 1100.00),
(10, 10, 'Online', '2024-12-10', 1550.00);

--
-- Triggers `payment`
--
DELIMITER $$
CREATE TRIGGER `Log_Payment_Modification` AFTER UPDATE ON `payment` FOR EACH ROW BEGIN
    -- Log only if Payment_Mode or Amount is changed
    IF OLD.Payment_Mode <> NEW.Payment_Mode OR OLD.Amount <> NEW.Amount THEN
        INSERT INTO Payment_Audit (Payment_ID, Old_Payment_Mode, New_Payment_Mode, Old_Amount, New_Amount, Change_Timestamp, Changed_By)
        VALUES (NEW.Payment_ID, OLD.Payment_Mode, NEW.Payment_Mode, OLD.Amount, NEW.Amount, CURRENT_TIMESTAMP, NEW.Booking_ID);
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Update_Booking_After_Payment` AFTER INSERT ON `payment` FOR EACH ROW BEGIN
    -- Update the Booking Status to 'Completed' after a successful payment
    UPDATE Bookings 
    SET Payment_Status = 'Completed'
    WHERE Booking_ID = NEW.Booking_ID;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `payment_audit`
--

CREATE TABLE `payment_audit` (
  `Audit_ID` int(11) NOT NULL,
  `Payment_ID` int(11) NOT NULL,
  `Old_Payment_Status` enum('Pending','Completed') NOT NULL,
  `New_Payment_Status` enum('Pending','Completed') NOT NULL,
  `Change_Timestamp` datetime DEFAULT current_timestamp(),
  `Changed_By` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `payment_overview`
-- (See below for the actual view)
--
CREATE TABLE `payment_overview` (
`Payment_ID` int(11)
,`Booking_ID` int(11)
,`Payment_Mode` enum('Cash','Online')
,`Amount` decimal(10,2)
,`Payment_Date` date
,`User_Name` varchar(100)
,`Payment_Status` enum('Pending','Completed')
);

-- --------------------------------------------------------

--
-- Table structure for table `routes`
--

CREATE TABLE `routes` (
  `Route_ID` int(11) NOT NULL,
  `Start_Station` int(11) NOT NULL,
  `End_Station` int(11) NOT NULL,
  `Distance` decimal(10,2) NOT NULL,
  `Duration` decimal(5,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `routes`
--

INSERT INTO `routes` (`Route_ID`, `Start_Station`, `End_Station`, `Distance`, `Duration`) VALUES
(1, 1, 2, 245.00, 6.00),
(2, 1, 3, 266.00, 6.50),
(3, 1, 4, 350.00, 8.00),
(4, 1, 5, 319.00, 7.00),
(5, 1, 6, 169.00, 4.00),
(6, 2, 3, 403.00, 10.00),
(7, 3, 4, 207.00, 5.00),
(8, 6, 7, 315.00, 8.00),
(9, 8, 9, 150.00, 3.00),
(10, 1, 10, 320.00, 7.00);

-- --------------------------------------------------------

--
-- Stand-in structure for view `routes_overview`
-- (See below for the actual view)
--
CREATE TABLE `routes_overview` (
`Route_ID` int(11)
,`Start_Station` int(11)
,`End_Station` int(11)
,`Distance` decimal(10,2)
,`Duration` decimal(5,2)
);

-- --------------------------------------------------------

--
-- Table structure for table `schedules`
--

CREATE TABLE `schedules` (
  `Schedule_ID` int(11) NOT NULL,
  `Train_ID` int(11) NOT NULL,
  `Route_ID` int(11) NOT NULL,
  `Departure_Time` datetime NOT NULL,
  `Arrival_Time` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `schedules`
--

INSERT INTO `schedules` (`Schedule_ID`, `Train_ID`, `Route_ID`, `Departure_Time`, `Arrival_Time`) VALUES
(1, 1, 1, '2024-12-01 07:30:00', '2024-12-01 13:30:00'),
(2, 2, 2, '2024-12-02 09:00:00', '2024-12-02 17:00:00'),
(3, 3, 3, '2024-12-03 06:00:00', '2024-12-03 13:00:00'),
(4, 4, 4, '2024-12-04 14:00:00', '2024-12-04 22:00:00'),
(5, 5, 5, '2024-12-05 15:30:00', '2024-12-05 22:30:00'),
(6, 6, 6, '2024-12-06 07:00:00', '2024-12-06 15:00:00'),
(7, 7, 7, '2024-12-07 05:30:00', '2024-12-07 12:30:00'),
(8, 8, 8, '2024-12-08 16:00:00', '2024-12-08 21:00:00'),
(9, 9, 9, '2024-12-09 08:00:00', '2024-12-09 16:00:00'),
(10, 10, 10, '2024-12-10 10:30:00', '2024-12-10 17:30:00');

-- --------------------------------------------------------

--
-- Table structure for table `stations`
--

CREATE TABLE `stations` (
  `Station_ID` int(11) NOT NULL,
  `Name` varchar(100) NOT NULL,
  `Location` text NOT NULL,
  `District` varchar(50) NOT NULL,
  `Phone_Number` varchar(15) DEFAULT NULL,
  `Manager_Name` varchar(100) DEFAULT NULL,
  `Established_Date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `stations`
--

INSERT INTO `stations` (`Station_ID`, `Name`, `Location`, `District`, `Phone_Number`, `Manager_Name`, `Established_Date`) VALUES
(1, 'Kamalapur', 'Kamalapur Railway Station, Dhaka', 'Dhaka', '0293456789', 'Jamal Uddin', '1968-06-01'),
(2, 'Chattogram Central', 'Central Station, Chattogram', 'Chattogram', '0312345678', 'Aminul Islam', '1950-08-15'),
(3, 'Sylhet Station', 'Sylhet City', 'Sylhet', '0821345678', 'Shakil Hossain', '1975-04-10'),
(4, 'Khulna Station', 'Khulna City', 'Khulna', '0412345678', 'Mahmuda Begum', '1960-11-25'),
(5, 'Rajshahi Station', 'Rajshahi City', 'Rajshahi', '0721345678', 'Mizanur Rahman', '1958-09-05'),
(6, 'Barishal Station', 'Barishal City', 'Barishal', '0431345678', 'Rubel Mia', '1962-07-15'),
(7, 'Gazipur Station', 'Gazipur City', 'Gazipur', '0681345678', 'Tahmina Sultana', '1970-05-25'),
(8, 'Cumilla Station', 'Cumilla City', 'Cumilla', '0812345678', 'Nafis Ahmed', '1956-03-10'),
(9, 'Mymensingh Station', 'Mymensingh City', 'Mymensingh', '0912345678', 'Anisur Rahman', '1965-12-01'),
(10, 'Rangpur Station', 'Rangpur City', 'Rangpur', '0521345678', 'Sadia Jahan', '1963-10-15');

-- --------------------------------------------------------

--
-- Table structure for table `tickets`
--

CREATE TABLE `tickets` (
  `Ticket_ID` int(11) NOT NULL,
  `Booking_ID` int(11) NOT NULL,
  `Seat_Number` varchar(10) NOT NULL,
  `Price` decimal(10,2) NOT NULL,
  `Journey_Date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tickets`
--

INSERT INTO `tickets` (`Ticket_ID`, `Booking_ID`, `Seat_Number`, `Price`, `Journey_Date`) VALUES
(1, 1, 'A1', 1500.00, '2024-12-01'),
(2, 2, 'B2', 1200.00, '2024-12-02'),
(3, 3, 'C3', 1300.00, '2024-12-03'),
(4, 4, 'D4', 1100.00, '2024-12-04'),
(5, 5, 'E5', 1400.00, '2024-12-05'),
(6, 6, 'F6', 1600.00, '2024-12-06'),
(7, 7, 'G7', 1250.00, '2024-12-07'),
(8, 8, 'H8', 1350.00, '2024-12-08'),
(9, 9, 'I9', 1100.00, '2024-12-09'),
(10, 10, 'J10', 1550.00, '2024-12-10');

--
-- Triggers `tickets`
--
DELIMITER $$
CREATE TRIGGER `Prevent_Double_Booking` BEFORE INSERT ON `tickets` FOR EACH ROW BEGIN
    DECLARE v_Seat_Count INT;
    
    -- Check if the seat is already booked for the specific train and journey date
    SELECT COUNT(*) INTO v_Seat_Count
    FROM Tickets 
    WHERE Train_ID = (SELECT Train_ID FROM Bookings WHERE Booking_ID = NEW.Booking_ID) 
    AND Seat_Number = NEW.Seat_Number
    AND Journey_Date = NEW.Journey_Date;
    
    -- If seat is already booked, raise an error
    IF v_Seat_Count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Seat already booked for this train on the selected date';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Update_Train_Capacity_After_Booking` AFTER INSERT ON `tickets` FOR EACH ROW BEGIN
    DECLARE v_Capacity INT;
    
    -- Fetch current capacity of the train
    SELECT Capacity INTO v_Capacity 
    FROM Trains 
    WHERE Train_ID = (SELECT Train_ID FROM Bookings WHERE Booking_ID = NEW.Booking_ID);
    
    -- Update the train capacity by reducing one seat
    UPDATE Trains 
    SET Capacity = v_Capacity - 1 
    WHERE Train_ID = (SELECT Train_ID FROM Bookings WHERE Booking_ID = NEW.Booking_ID);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `trains`
--

CREATE TABLE `trains` (
  `Train_ID` int(11) NOT NULL,
  `Train_Name` varchar(100) NOT NULL,
  `Capacity` int(11) NOT NULL,
  `Class` enum('AC','Non-AC','Sleeper') NOT NULL,
  `Status` enum('Running','Maintenance') DEFAULT 'Running'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `trains`
--

INSERT INTO `trains` (`Train_ID`, `Train_Name`, `Capacity`, `Class`, `Status`) VALUES
(1, 'Suborno Express', 800, 'AC', 'Running'),
(2, 'Chattala Express', 500, 'Non-AC', 'Running'),
(3, 'Mohanganj Express', 700, 'AC', 'Running'),
(4, 'Drutajan Express', 1000, 'Sleeper', 'Maintenance'),
(5, 'Parabat Express', 900, 'AC', 'Running'),
(6, 'Mahanagar Godhuli', 850, 'Non-AC', 'Running'),
(7, 'Kurigram Express', 750, 'Sleeper', 'Running'),
(8, 'Teesta Express', 400, 'Non-AC', 'Running'),
(9, 'Ekota Express', 1000, 'AC', 'Maintenance'),
(10, 'Sonar Bangla Express', 850, 'Non-AC', 'Running');

-- --------------------------------------------------------

--
-- Table structure for table `train_classes`
--

CREATE TABLE `train_classes` (
  `Class_ID` int(11) NOT NULL,
  `Class_Name` enum('AC','Non-AC','Sleeper') NOT NULL,
  `Description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `train_classes`
--

INSERT INTO `train_classes` (`Class_ID`, `Class_Name`, `Description`) VALUES
(1, 'AC', 'Air-conditioned coaches offering comfortable seating and climate control.'),
(2, 'Non-AC', 'Standard seating coaches without air-conditioning, providing budget-friendly travel.'),
(3, 'Sleeper', 'Coaches with bunk beds for long-distance overnight travel, offering a low-cost option.');

-- --------------------------------------------------------

--
-- Stand-in structure for view `train_schedule_details`
-- (See below for the actual view)
--
CREATE TABLE `train_schedule_details` (
`Schedule_ID` int(11)
,`Train_Name` varchar(100)
,`Start_Station` int(11)
,`End_Station` int(11)
,`Departure_Time` datetime
,`Arrival_Time` datetime
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `train_status`
-- (See below for the actual view)
--
CREATE TABLE `train_status` (
`Train_ID` int(11)
,`Train_Name` varchar(100)
,`Status` enum('Running','Maintenance')
);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `User_ID` int(11) NOT NULL,
  `Name` varchar(100) NOT NULL,
  `Phone_Number` varchar(15) NOT NULL,
  `Email` varchar(100) DEFAULT NULL,
  `Address` text NOT NULL,
  `Gender` enum('Male','Female','Other') NOT NULL,
  `Date_of_Birth` date NOT NULL,
  `National_ID` varchar(20) NOT NULL,
  `Passport_Number` varchar(20) DEFAULT NULL,
  `Emergency_Contact` varchar(15) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`User_ID`, `Name`, `Phone_Number`, `Email`, `Address`, `Gender`, `Date_of_Birth`, `National_ID`, `Passport_Number`, `Emergency_Contact`) VALUES
(1, 'Abdul Karim', '01711000001', 'karim@gmail.com', 'Dhaka', 'Male', '1990-05-10', '1234567890', 'BP12345', '01822000001'),
(2, 'Hasina Begum', '01811000002', 'hasina@gmail.com', 'Chattogram', 'Female', '1985-03-15', '9876543210', 'BP12346', '01933000002'),
(3, 'Rajib Khan', '01911000003', 'rajib@gmail.com', 'Khulna', 'Male', '1995-07-22', '1357908642', 'BP12347', '01744000003'),
(4, 'Sumaiya Islam', '01611000004', 'sumaiya@gmail.com', 'Rajshahi', 'Female', '1993-09-30', '2468013579', 'BP12348', '01855000004'),
(5, 'Sajid Rahman', '01511000005', 'sajid@gmail.com', 'Sylhet', 'Male', '1997-12-05', '3692581470', 'BP12349', '01766000005'),
(6, 'Rumana Akter', '01411000006', 'rumana@gmail.com', 'Barishal', 'Female', '1990-11-18', '3216549870', 'BP12350', '01977000006'),
(7, 'Mehedi Hasan', '01721000007', 'mehedi@gmail.com', 'Gazipur', 'Male', '1992-08-25', '1122334455', 'BP12351', '01688000007'),
(8, 'Nasrin Nahar', '01831000008', 'nasrin@gmail.com', 'Cumilla', 'Female', '1988-02-20', '9988776655', 'BP12352', '01799000008'),
(9, 'Tanvir Ahmed', '01541000009', 'tanvir@gmail.com', 'Mymensingh', 'Male', '1985-04-11', '5566778899', 'BP12353', '01800000009'),
(10, 'Mithila Sultana', '01651000010', 'mithila@gmail.com', 'Rangpur', 'Female', '1991-06-15', '4433221100', 'BP12354', '01911000010');

-- --------------------------------------------------------

--
-- Table structure for table `user_audit`
--

CREATE TABLE `user_audit` (
  `Audit_ID` int(11) NOT NULL,
  `User_ID` int(11) NOT NULL,
  `Action_Type` varchar(50) NOT NULL,
  `Action_Description` text NOT NULL,
  `Action_Timestamp` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure for view `booking_details`
--
DROP TABLE IF EXISTS `booking_details`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `booking_details`  AS SELECT `b`.`Booking_ID` AS `Booking_ID`, `u`.`Name` AS `User_Name`, `t`.`Train_Name` AS `Train_Name`, `b`.`Booking_Date` AS `Booking_Date`, `b`.`Payment_Status` AS `Payment_Status` FROM ((`bookings` `b` join `users` `u` on(`b`.`User_ID` = `u`.`User_ID`)) join `trains` `t` on(`b`.`Train_ID` = `t`.`Train_ID`)) ;

-- --------------------------------------------------------

--
-- Structure for view `feedback_summary`
--
DROP TABLE IF EXISTS `feedback_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `feedback_summary`  AS SELECT `f`.`Feedback_ID` AS `Feedback_ID`, `u`.`Name` AS `User_Name`, `f`.`Feedback_Text` AS `Feedback_Text`, `f`.`Rating` AS `Rating` FROM (`feedback` `f` join `users` `u` on(`f`.`User_ID` = `u`.`User_ID`)) ;

-- --------------------------------------------------------

--
-- Structure for view `luggage_details`
--
DROP TABLE IF EXISTS `luggage_details`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `luggage_details`  AS SELECT `l`.`Luggage_ID` AS `Luggage_ID`, `l`.`Weight` AS `Weight`, `l`.`Extra_Charge` AS `Extra_Charge`, `b`.`Booking_ID` AS `Booking_ID`, `b`.`User_ID` AS `User_ID` FROM (`luggage` `l` join `bookings` `b` on(`l`.`Booking_ID` = `b`.`Booking_ID`)) ;

-- --------------------------------------------------------

--
-- Structure for view `payment_overview`
--
DROP TABLE IF EXISTS `payment_overview`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `payment_overview`  AS SELECT `p`.`Payment_ID` AS `Payment_ID`, `b`.`Booking_ID` AS `Booking_ID`, `p`.`Payment_Mode` AS `Payment_Mode`, `p`.`Amount` AS `Amount`, `p`.`Payment_Date` AS `Payment_Date`, `u`.`Name` AS `User_Name`, `b`.`Payment_Status` AS `Payment_Status` FROM ((`payment` `p` join `bookings` `b` on(`p`.`Booking_ID` = `b`.`Booking_ID`)) join `users` `u` on(`b`.`User_ID` = `u`.`User_ID`)) ;

-- --------------------------------------------------------

--
-- Structure for view `routes_overview`
--
DROP TABLE IF EXISTS `routes_overview`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `routes_overview`  AS SELECT `routes`.`Route_ID` AS `Route_ID`, `routes`.`Start_Station` AS `Start_Station`, `routes`.`End_Station` AS `End_Station`, `routes`.`Distance` AS `Distance`, `routes`.`Duration` AS `Duration` FROM `routes` ;

-- --------------------------------------------------------

--
-- Structure for view `train_schedule_details`
--
DROP TABLE IF EXISTS `train_schedule_details`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `train_schedule_details`  AS SELECT `s`.`Schedule_ID` AS `Schedule_ID`, `t`.`Train_Name` AS `Train_Name`, `r`.`Start_Station` AS `Start_Station`, `r`.`End_Station` AS `End_Station`, `s`.`Departure_Time` AS `Departure_Time`, `s`.`Arrival_Time` AS `Arrival_Time` FROM ((`schedules` `s` join `trains` `t` on(`s`.`Train_ID` = `t`.`Train_ID`)) join `routes` `r` on(`s`.`Route_ID` = `r`.`Route_ID`)) ;

-- --------------------------------------------------------

--
-- Structure for view `train_status`
--
DROP TABLE IF EXISTS `train_status`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `train_status`  AS SELECT `trains`.`Train_ID` AS `Train_ID`, `trains`.`Train_Name` AS `Train_Name`, `trains`.`Status` AS `Status` FROM `trains` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`Booking_ID`),
  ADD KEY `User_ID` (`User_ID`),
  ADD KEY `Train_ID` (`Train_ID`);

--
-- Indexes for table `booking_audit`
--
ALTER TABLE `booking_audit`
  ADD PRIMARY KEY (`Audit_ID`),
  ADD KEY `Booking_ID` (`Booking_ID`),
  ADD KEY `Changed_By` (`Changed_By`);

--
-- Indexes for table `complaints`
--
ALTER TABLE `complaints`
  ADD PRIMARY KEY (`Complaint_ID`),
  ADD KEY `User_ID` (`User_ID`);

--
-- Indexes for table `employees`
--
ALTER TABLE `employees`
  ADD PRIMARY KEY (`Employee_ID`),
  ADD UNIQUE KEY `Phone_Number` (`Phone_Number`),
  ADD UNIQUE KEY `Email` (`Email`),
  ADD KEY `Station_Assigned` (`Station_Assigned`);

--
-- Indexes for table `fares`
--
ALTER TABLE `fares`
  ADD PRIMARY KEY (`Fare_ID`),
  ADD KEY `Train_ID` (`Train_ID`),
  ADD KEY `Route_ID` (`Route_ID`),
  ADD KEY `Class_ID` (`Class_ID`);

--
-- Indexes for table `feedback`
--
ALTER TABLE `feedback`
  ADD PRIMARY KEY (`Feedback_ID`),
  ADD KEY `User_ID` (`User_ID`);

--
-- Indexes for table `luggage`
--
ALTER TABLE `luggage`
  ADD PRIMARY KEY (`Luggage_ID`),
  ADD KEY `Booking_ID` (`Booking_ID`);

--
-- Indexes for table `maintenance`
--
ALTER TABLE `maintenance`
  ADD PRIMARY KEY (`Maintenance_ID`),
  ADD KEY `Train_ID` (`Train_ID`);

--
-- Indexes for table `payment`
--
ALTER TABLE `payment`
  ADD PRIMARY KEY (`Payment_ID`),
  ADD KEY `Booking_ID` (`Booking_ID`);

--
-- Indexes for table `payment_audit`
--
ALTER TABLE `payment_audit`
  ADD PRIMARY KEY (`Audit_ID`),
  ADD KEY `Payment_ID` (`Payment_ID`),
  ADD KEY `Changed_By` (`Changed_By`);

--
-- Indexes for table `routes`
--
ALTER TABLE `routes`
  ADD PRIMARY KEY (`Route_ID`),
  ADD KEY `Start_Station` (`Start_Station`),
  ADD KEY `End_Station` (`End_Station`);

--
-- Indexes for table `schedules`
--
ALTER TABLE `schedules`
  ADD PRIMARY KEY (`Schedule_ID`),
  ADD KEY `Train_ID` (`Train_ID`),
  ADD KEY `Route_ID` (`Route_ID`);

--
-- Indexes for table `stations`
--
ALTER TABLE `stations`
  ADD PRIMARY KEY (`Station_ID`),
  ADD UNIQUE KEY `Phone_Number` (`Phone_Number`);

--
-- Indexes for table `tickets`
--
ALTER TABLE `tickets`
  ADD PRIMARY KEY (`Ticket_ID`),
  ADD KEY `Booking_ID` (`Booking_ID`);

--
-- Indexes for table `trains`
--
ALTER TABLE `trains`
  ADD PRIMARY KEY (`Train_ID`);

--
-- Indexes for table `train_classes`
--
ALTER TABLE `train_classes`
  ADD PRIMARY KEY (`Class_ID`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`User_ID`),
  ADD UNIQUE KEY `Phone_Number` (`Phone_Number`),
  ADD UNIQUE KEY `National_ID` (`National_ID`),
  ADD UNIQUE KEY `Email` (`Email`),
  ADD UNIQUE KEY `Passport_Number` (`Passport_Number`);

--
-- Indexes for table `user_audit`
--
ALTER TABLE `user_audit`
  ADD PRIMARY KEY (`Audit_ID`),
  ADD KEY `User_ID` (`User_ID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `Booking_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `booking_audit`
--
ALTER TABLE `booking_audit`
  MODIFY `Audit_ID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `complaints`
--
ALTER TABLE `complaints`
  MODIFY `Complaint_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `employees`
--
ALTER TABLE `employees`
  MODIFY `Employee_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `fares`
--
ALTER TABLE `fares`
  MODIFY `Fare_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `feedback`
--
ALTER TABLE `feedback`
  MODIFY `Feedback_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `luggage`
--
ALTER TABLE `luggage`
  MODIFY `Luggage_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `maintenance`
--
ALTER TABLE `maintenance`
  MODIFY `Maintenance_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `payment`
--
ALTER TABLE `payment`
  MODIFY `Payment_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `payment_audit`
--
ALTER TABLE `payment_audit`
  MODIFY `Audit_ID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `routes`
--
ALTER TABLE `routes`
  MODIFY `Route_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `schedules`
--
ALTER TABLE `schedules`
  MODIFY `Schedule_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `stations`
--
ALTER TABLE `stations`
  MODIFY `Station_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `tickets`
--
ALTER TABLE `tickets`
  MODIFY `Ticket_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `trains`
--
ALTER TABLE `trains`
  MODIFY `Train_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `train_classes`
--
ALTER TABLE `train_classes`
  MODIFY `Class_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `User_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `user_audit`
--
ALTER TABLE `user_audit`
  MODIFY `Audit_ID` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`User_ID`) REFERENCES `users` (`User_ID`),
  ADD CONSTRAINT `bookings_ibfk_2` FOREIGN KEY (`Train_ID`) REFERENCES `trains` (`Train_ID`);

--
-- Constraints for table `booking_audit`
--
ALTER TABLE `booking_audit`
  ADD CONSTRAINT `booking_audit_ibfk_1` FOREIGN KEY (`Booking_ID`) REFERENCES `bookings` (`Booking_ID`),
  ADD CONSTRAINT `booking_audit_ibfk_2` FOREIGN KEY (`Changed_By`) REFERENCES `users` (`User_ID`);

--
-- Constraints for table `complaints`
--
ALTER TABLE `complaints`
  ADD CONSTRAINT `complaints_ibfk_1` FOREIGN KEY (`User_ID`) REFERENCES `users` (`User_ID`);

--
-- Constraints for table `employees`
--
ALTER TABLE `employees`
  ADD CONSTRAINT `employees_ibfk_1` FOREIGN KEY (`Station_Assigned`) REFERENCES `stations` (`Station_ID`);

--
-- Constraints for table `fares`
--
ALTER TABLE `fares`
  ADD CONSTRAINT `fares_ibfk_1` FOREIGN KEY (`Train_ID`) REFERENCES `trains` (`Train_ID`),
  ADD CONSTRAINT `fares_ibfk_2` FOREIGN KEY (`Route_ID`) REFERENCES `routes` (`Route_ID`),
  ADD CONSTRAINT `fares_ibfk_3` FOREIGN KEY (`Class_ID`) REFERENCES `train_classes` (`Class_ID`);

--
-- Constraints for table `feedback`
--
ALTER TABLE `feedback`
  ADD CONSTRAINT `feedback_ibfk_1` FOREIGN KEY (`User_ID`) REFERENCES `users` (`User_ID`);

--
-- Constraints for table `luggage`
--
ALTER TABLE `luggage`
  ADD CONSTRAINT `luggage_ibfk_1` FOREIGN KEY (`Booking_ID`) REFERENCES `bookings` (`Booking_ID`);

--
-- Constraints for table `maintenance`
--
ALTER TABLE `maintenance`
  ADD CONSTRAINT `maintenance_ibfk_1` FOREIGN KEY (`Train_ID`) REFERENCES `trains` (`Train_ID`);

--
-- Constraints for table `payment`
--
ALTER TABLE `payment`
  ADD CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`Booking_ID`) REFERENCES `bookings` (`Booking_ID`);

--
-- Constraints for table `payment_audit`
--
ALTER TABLE `payment_audit`
  ADD CONSTRAINT `payment_audit_ibfk_1` FOREIGN KEY (`Payment_ID`) REFERENCES `payment` (`Payment_ID`),
  ADD CONSTRAINT `payment_audit_ibfk_2` FOREIGN KEY (`Changed_By`) REFERENCES `users` (`User_ID`);

--
-- Constraints for table `routes`
--
ALTER TABLE `routes`
  ADD CONSTRAINT `routes_ibfk_1` FOREIGN KEY (`Start_Station`) REFERENCES `stations` (`Station_ID`),
  ADD CONSTRAINT `routes_ibfk_2` FOREIGN KEY (`End_Station`) REFERENCES `stations` (`Station_ID`);

--
-- Constraints for table `schedules`
--
ALTER TABLE `schedules`
  ADD CONSTRAINT `schedules_ibfk_1` FOREIGN KEY (`Train_ID`) REFERENCES `trains` (`Train_ID`),
  ADD CONSTRAINT `schedules_ibfk_2` FOREIGN KEY (`Route_ID`) REFERENCES `routes` (`Route_ID`);

--
-- Constraints for table `tickets`
--
ALTER TABLE `tickets`
  ADD CONSTRAINT `tickets_ibfk_1` FOREIGN KEY (`Booking_ID`) REFERENCES `bookings` (`Booking_ID`);

--
-- Constraints for table `user_audit`
--
ALTER TABLE `user_audit`
  ADD CONSTRAINT `user_audit_ibfk_1` FOREIGN KEY (`User_ID`) REFERENCES `users` (`User_ID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
